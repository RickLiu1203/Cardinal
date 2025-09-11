const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const cors = require("cors")({origin: true});
const apn = require("node-apn");

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

exports.getPortfolio = onRequest(async (req, res) => {
  return cors(req, res, async () => {
    try {
      const id = req.query.id;
      if (!id) {
        return res.status(400).json({error: "missing id parameter"});
      }

      // Read from the same Firestore path your main app uses
      const snapshot = await admin.firestore()
          .collection("users")
          .doc(id)
          .collection("sections")
          .doc("personalDetails")
          .get();

      if (!snapshot.exists) {
        return res.status(404).json({error: "portfolio not found"});
      }

      const data = snapshot.data();

      // Also load about section and experiences
      const aboutSnap = await admin.firestore()
          .collection("users").doc(id)
          .collection("sections").doc("about")
          .get();
      let about = null;
      if (aboutSnap.exists) {
        const aboutData = aboutSnap.data() || {};
        about = {
          header: aboutData.header || "",
          subtitle: aboutData.subtitle || "",
          body: aboutData.body || "",
        };
      }

      const expSnap = await admin.firestore()
          .collection("users").doc(id)
          .collection("sections").doc("experiences")
          .collection("items")
          .get();
      const experiences = expSnap.docs.map((d) => {
        const ed = d.data() || {};
        console.log(`Experience data for ${ed.role || "Unknown"}:`, ed.skills);
        return {
          id: d.id,
          company: ed.company || "",
          role: ed.role || "",
          startDate: ed.startDateString || null,
          endDate: ed.endDateString || null,
          description: ed.description || "",
          skills: ed.skills || null,
        };
      });
      experiences.sort((a, b) => {
        if (a.endDate && b.endDate) return a.endDate > b.endDate ? -1 : 1;
        if (!a.endDate && b.endDate) return 1;
        if (a.endDate && !b.endDate) return -1;
        return (a.startDate || "") > (b.startDate || "") ? -1 : 1;
      });

      // Load resume
      const resumeSnap = await admin.firestore()
          .collection("users").doc(id)
          .collection("sections").doc("resume")
          .get();
      let resume = null;
      if (resumeSnap.exists) {
        const rd = resumeSnap.data() || {};
        if (rd.fileName && rd.downloadURL) {
          const uploadedAt = rd.uploadedAt ?
            (rd.uploadedAt.toDate ?
              rd.uploadedAt.toDate().toLocaleDateString() :
              "Unknown") :
            "Unknown";
          resume = {
            fileName: rd.fileName,
            downloadURL: rd.downloadURL,
            uploadedAt,
          };
        }
      }

      // Load skills
      const skillsSnap = await admin.firestore()
          .collection("users").doc(id)
          .collection("sections").doc("skills")
          .get();
      let skills = null;
      if (skillsSnap.exists) {
        const sd = skillsSnap.data() || {};
        if (sd.skills && Array.isArray(sd.skills)) {
          skills = sd.skills;
        }
      }

      // Load projects
      const projectsSnap = await admin.firestore()
          .collection("users").doc(id)
          .collection("sections").doc("projects")
          .collection("items")
          .orderBy("createdAt", "desc")
          .get();
      const projects = projectsSnap.docs.map((d) => {
        const pd = d.data() || {};
        return {
          id: d.id,
          title: pd.title || "",
          description: pd.description || null,
          tools: pd.tools || [],
          link: pd.link || null,
        };
      });

      // Load section order
      const sectionOrderSnap = await admin.firestore()
          .collection("users").doc(id)
          .collection("settings").doc("sectionOrder")
          .get();
      let sectionOrder = null;
      if (sectionOrderSnap.exists) {
        const sod = sectionOrderSnap.data() || {};
        if (sod.sectionOrder && Array.isArray(sod.sectionOrder)) {
          sectionOrder = sod.sectionOrder;
        }
      }

      // Return the structure the App Clip expects
      return res.json({
        firstName: data.firstName || "",
        lastName: data.lastName || "",
        subtitle: data.subtitle || "",
        email: data.email || "",
        linkedIn: data.linkedIn || "",
        phoneNumber: data.phoneNumber || "",
        github: data.github || "",
        website: data.website || "",
        about,
        experiences,
        resume,
        skills,
        projects,
        sectionOrder,
      });
    } catch (error) {
      console.error("Error fetching portfolio:", error);
      return res.status(500).json({error: "internal server error"});
    }
  });
});

// Streams files from Firebase Storage so that cardinalapp.me/files/<path> works
exports.serveFile = onRequest(async (req, res) => {
  return cors(req, res, async () => {
    try {
      const prefix = "/files/";
      const originalPath = req.path || req.url || "";
      const idx = originalPath.indexOf(prefix);
      if (idx === -1) {
        return res.status(400).send("Bad request");
      }
      let storagePath = originalPath.substring(idx + prefix.length);
      if (!storagePath) {
        return res.status(400).send("Missing file path");
      }
      storagePath = decodeURIComponent(storagePath);

      const bucket = admin.storage().bucket();
      const file = bucket.file(storagePath);
      const [exists] = await file.exists();
      if (!exists) {
        return res.status(404).send("Not found");
      }

      // Infer content type from extension; default to application/pdf
      const isPdf = storagePath.toLowerCase().endsWith(".pdf");
      res.set(
          "Content-Type",
          isPdf ? "application/pdf" : "application/octet-stream",
      );
      const fileName = storagePath.split("/").pop();
      res.set(
          "Content-Disposition",
          `inline; filename="${fileName}"`,
      );
      res.set("Cache-Control", "public, max-age=3600, s-maxage=3600");

      const stream = file.createReadStream();
      stream.on("error", (err) => {
        console.error("Error streaming file:", err);
        if (!res.headersSent) {
          res.status(500).send("Error reading file");
        }
      });
      stream.pipe(res);
    } catch (error) {
      console.error("serveFile error:", error);
      return res.status(500).send("Internal server error");
    }
  });
});

// Logs an analytics event from the App Clip
exports.logClipEvent = onRequest(async (req, res) => {
  return cors(req, res, async () => {
    try {
      if (req.method !== "POST") {
        return res.status(405).json({error: "method not allowed"});
      }
      const {ownerId, deviceId, visitorName, action, meta} = req.body || {};
      if (!ownerId || !deviceId || !action) {
        return res.status(400).json({error: "missing required fields"});
      }

      const db = admin.firestore();
      const statsRef = db.collection("users").doc(ownerId)
          .collection("analytics").doc("stats");
      const visitorRef = db.collection("users").doc(ownerId)
          .collection("analytics").doc("visitors")
          .collection("devices").doc(deviceId);
      const eventsCol = db.collection("users").doc(ownerId)
          .collection("analytics").doc("events").collection("items");

      await db.runTransaction(async (tx) => {
        const [statsSnap, visitorSnap] = await Promise.all([
          tx.get(statsRef),
          tx.get(visitorRef),
        ]);

        const statsData = statsSnap.exists ?
          statsSnap.data() :
          {uniqueVisitors: 0, totalActions: 0};
        let {uniqueVisitors, totalActions} = statsData;

        // Create event doc
        const eventDoc = eventsCol.doc();
        tx.set(eventDoc, {
          action,
          meta: meta || {},
          visitorName: visitorName || "anonymous",
          deviceId,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Increment totals
        totalActions += 1;
        if (!visitorSnap.exists) {
          tx.set(visitorRef, {
            firstSeenAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          uniqueVisitors += 1;
        }

        tx.set(statsRef, {uniqueVisitors, totalActions}, {merge: true});
      });

      return res.json({ok: true});
    } catch (error) {
      console.error("logClipEvent error:", error);
      return res.status(500).json({error: "internal server error"});
    }
  });
});

// Returns analytics stats and recent events
exports.getAnalytics = onRequest(async (req, res) => {
  return cors(req, res, async () => {
    try {
      const ownerId = req.query.ownerId;
      if (!ownerId) {
        return res.status(400).json({error: "missing ownerId"});
      }

      const db = admin.firestore();
      const statsSnap = await db.collection("users").doc(ownerId)
          .collection("analytics").doc("stats").get();
      const stats = statsSnap.exists ?
        statsSnap.data() :
        {uniqueVisitors: 0, totalActions: 0};

      const eventsSnap = await db.collection("users").doc(ownerId)
          .collection("analytics").doc("events").collection("items")
          .orderBy("createdAt", "desc").limit(200).get();

      const events = eventsSnap.docs.map((d) => {
        const ed = d.data() || {};
        let timestamp = "";
        if (ed.createdAt && ed.createdAt.toDate) {
          timestamp = ed.createdAt.toDate().toISOString();
        }
        return {
          id: d.id,
          action: ed.action || "",
          visitorName: ed.visitorName || "anonymous",
          deviceId: ed.deviceId || "",
          timestamp,
          meta: ed.meta || {},
        };
      });

      return res.json({
        stats: {
          uniqueVisitors: stats.uniqueVisitors || 0,
          totalActions: stats.totalActions || 0,
        },
        events,
      });
    } catch (error) {
      console.error("getAnalytics error:", error);
      return res.status(500).json({error: "internal server error"});
    }
  });
});

// Clears all analytics data for a specific owner
exports.clearAllAnalytics = onRequest(async (req, res) => {
  return cors(req, res, async () => {
    try {
      if (req.method !== "POST") {
        return res.status(405).json({error: "method not allowed"});
      }

      const {ownerId} = req.body || {};
      if (!ownerId) {
        return res.status(400).json({error: "missing ownerId"});
      }

      const db = admin.firestore();

      // Delete all analytics data in a batch operation
      const batch = db.batch();

      // Clear stats
      const statsRef = db.collection("users").doc(ownerId)
          .collection("analytics").doc("stats");
      batch.set(statsRef, {uniqueVisitors: 0, totalActions: 0});

      // Clear all events
      const eventsCol = db.collection("users").doc(ownerId)
          .collection("analytics").doc("events").collection("items");
      const eventsSnap = await eventsCol.get();
      eventsSnap.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      // Clear all visitors
      const visitorsCol = db.collection("users").doc(ownerId)
          .collection("analytics").doc("visitors").collection("devices");
      const visitorsSnap = await visitorsCol.get();
      visitorsSnap.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();

      console.log(`🧹 All analytics data cleared for owner: ${ownerId}`);
      return res.json({
        ok: true,
        message: "Analytics data cleared successfully",
      });
    } catch (error) {
      console.error("clearAllAnalytics error:", error);
      return res.status(500).json({error: "internal server error"});
    }
  });
});

// Returns paginated analytics events
exports.getAnalyticsPage = onRequest(async (req, res) => {
  return cors(req, res, async () => {
    try {
      const ownerId = req.query.ownerId;
      let pageSize = parseInt(req.query.pageSize || "50", 10);
      const startAfterId = req.query.startAfterId || null;
      if (!ownerId) {
        return res.status(400).json({error: "missing ownerId"});
      }
      if (!Number.isFinite(pageSize) || pageSize <= 0) pageSize = 50;
      pageSize = Math.min(100, Math.max(10, pageSize));

      const db = admin.firestore();
      const eventsCol = db.collection("users").doc(ownerId)
          .collection("analytics").doc("events").collection("items");

      let query = eventsCol.orderBy("createdAt", "desc").limit(pageSize);
      if (startAfterId) {
        const startDoc = await eventsCol.doc(startAfterId).get();
        if (startDoc.exists) {
          query = query.startAfter(startDoc);
        }
      }

      const snap = await query.get();
      const docs = snap.docs;
      const events = docs.map((d) => {
        const ed = d.data() || {};
        let timestamp = "";
        if (ed.createdAt && ed.createdAt.toDate) {
          timestamp = ed.createdAt.toDate().toISOString();
        }
        return {
          id: d.id,
          action: ed.action || "",
          visitorName: ed.visitorName || "anonymous",
          deviceId: ed.deviceId || "",
          timestamp,
          meta: ed.meta || {},
        };
      });

      const nextCursor = docs.length === pageSize ?
        docs[docs.length - 1].id : null;

      return res.json({
        events,
        nextCursor,
      });
    } catch (error) {
      console.error("getAnalyticsPage error:", error);
      return res.status(500).json({error: "internal server error"});
    }
  });
});

// Schedules a push (server-side delay) to an APNs device token
// after N seconds (App Clip use)

// Production APNs Secrets
const APNS_TEAM_ID = defineSecret("APNS_TEAM_ID");
const APNS_KEY_ID = defineSecret("APNS_KEY_ID");
const APNS_P8 = defineSecret("APNS_P8");

// Development APNs Secrets
const APNS_TEAM_ID_DEV = defineSecret("APNS_TEAM_ID_DEV");
const APNS_KEY_ID_DEV = defineSecret("APNS_KEY_ID_DEV");
const APNS_P8_DEV = defineSecret("APNS_P8_DEV");

// Development/Sandbox APNs Function
exports.scheduleClipPushDev = onRequest({
  secrets: [APNS_TEAM_ID_DEV, APNS_KEY_ID_DEV, APNS_P8_DEV],
}, async (req, res) => {
  return cors(req, res, async () => {
    try {
      if (req.method !== "POST") {
        return res.status(405).json({error: "method not allowed"});
      }
      console.log("📥 DEV: Received request body:",
          JSON.stringify(req.body, null, 2));
      const {
        token,
        seconds,
        title,
        body,
        bundleId,
      } = req.body || {};

      if (!token || !seconds || !bundleId) {
        return res.status(400).json({
          error: "missing token, seconds, or bundleId",
        });
      }

      // Read APNs development credentials
      console.log("📱 DEV: Reading development APNs credentials...");
      const teamId = APNS_TEAM_ID_DEV.value();
      const keyId = APNS_KEY_ID_DEV.value();
      const p8 = APNS_P8_DEV.value();
      console.log("📱 DEV: Development APNs credentials loaded -",
          `teamId: ${teamId ? "present" : "missing"},`,
          `keyId: ${keyId ? "present" : "missing"},`,
          `p8: ${p8 ? "present" : "missing"}`);

      if (!teamId || !keyId || !p8) {
        console.error("📱 DEV: Missing development APNs credentials");
        return res.status(500).json({
          error: "missing development APNs credentials",
        });
      }

      console.log("📱 DEV: Decoding development P8 key...");
      const p8Key = Buffer.from(p8, "base64").toString("utf8");
      console.log(`📱 DEV: P8 key decoded, length: ${p8Key.length} chars`);

      // Configure APNs provider for SANDBOX
      console.log("📱 DEV: Creating sandbox APNs provider...");
      const apnProvider = new apn.Provider({
        token: {
          key: p8Key,
          keyId: keyId,
          teamId: teamId,
        },
        production: false, // Always sandbox for dev function
      });

      // Create notification
      const notification = new apn.Notification();
      const alertTitle = title || "Thanks for checking my work out!";
      const alertBody = body || "Don't forget to add my email or LinkedIn!";

      // Add unique identifier to prevent iOS deduplication
      // Generate proper UUID format for APNs notification ID
      const uniqueId = require("crypto").randomUUID();
      console.log("📱 DEV: Creating unique notification UUID:", uniqueId);

      console.log("📱 DEV: Setting notification content:",
          `title="${alertTitle}", body="${alertBody}"`);
      notification.alert = {
        title: alertTitle,
        body: alertBody,
      };
      notification.sound = "default";
      notification.topic = bundleId;
      notification.id = uniqueId; // Unique notification ID
      notification.payload = {
        notificationId: uniqueId,
        timestamp: Date.now(),
      }; // Prevent duplicate

      // Wait before sending
      const delayMs = Number(seconds) * 1000;
      console.log(`📱 DEV: Waiting ${delayMs}ms before sending...`);
      await new Promise((r) => setTimeout(r, delayMs));

      // Send notification
      console.log("📱 DEV: Sending push notification to sandbox...");
      const result = await apnProvider.send(notification, token);
      console.log("📱 DEV: Sandbox APNs response:",
          JSON.stringify(result, null, 2));

      apnProvider.shutdown();

      if (result.sent && result.sent.length > 0) {
        console.log("📱 DEV: Push notification sent successfully!");

        // Log simple analytics event for notification
        try {
          const {ownerId, deviceId, visitorName} = req.body || {};
          if (ownerId && deviceId) {
            console.log("📊 DEV: Logging notification_sent event");

            // Simple HTTP call to existing logClipEvent function
            const logUrl = "https://us-central1-cardinalapp-4279c.cloudfunctions.net/logClipEvent";
            const logBody = {
              ownerId: ownerId,
              deviceId: deviceId,
              visitorName: visitorName || "anonymous",
              action: "notification_sent",
              meta: {environment: "sandbox"},
            };

            fetch(logUrl, {
              method: "POST",
              headers: {"Content-Type": "application/json"},
              body: JSON.stringify(logBody),
            }).catch((err) => console.error("📊 DEV: Log request failed:", err));
          }
        } catch (logError) {
          console.error("📊 DEV: Failed to log notification event:", logError);
        }

        return res.json({
          ok: true,
          environment: "sandbox",
          sent: result.sent.length,
          failed: result.failed.length,
        });
      } else {
        console.error("📱 DEV: Push notification failed:", result.failed[0]);
        return res.status(500).json({
          error: "push notification failed",
          environment: "sandbox",
          details: result.failed[0],
        });
      }
    } catch (error) {
      console.error("📱 DEV: Error in scheduleClipPushDev:", error);
      return res.status(500).json({error: "internal server error"});
    }
  });
});

// Production APNs Function
exports.scheduleClipPush = onRequest({
  secrets: [APNS_TEAM_ID, APNS_KEY_ID, APNS_P8]}, async (req, res) => {
  return cors(req, res, async () => {
    try {
      if (req.method !== "POST") {
        return res.status(405).json({error: "method not allowed"});
      }
      console.log("📥 PROD: Received request body:",
          JSON.stringify(req.body, null, 2));
      const {
        token,
        seconds,
        title,
        body,
        bundleId,
      } = req.body || {};
      if (!token || !seconds || !bundleId) {
        return res.status(400).json({
          error: "missing token, seconds, or bundleId",
        });
      }

      // Read production APNs credentials
      console.log("🏭 PROD: Reading production APNs credentials...");
      const teamId = APNS_TEAM_ID.value();
      const keyId = APNS_KEY_ID.value();
      const p8 = APNS_P8.value();
      console.log("🏭 PROD: Production APNs credentials loaded -",
          `teamId: ${teamId ? "present" : "missing"},`,
          `keyId: ${keyId ? "present" : "missing"},`,
          `p8: ${p8 ? "present" : "missing"}`);
      if (!teamId || !keyId || !p8) {
        console.error("🏭 PROD: Missing production APNs credentials");
        return res.status(500).json({
          error: "missing production APNs credentials",
        });
      }

      console.log("🏭 PROD: Decoding production P8 key...");
      const p8Key = Buffer.from(p8, "base64").toString("utf8");
      console.log(`🏭 PROD: P8 key decoded, length: ${p8Key.length} chars`);

      // Configure APNs provider for PRODUCTION
      console.log("🏭 PROD: Creating production APNs provider...");
      const apnProvider = new apn.Provider({
        token: {
          key: p8Key,
          keyId: keyId,
          teamId: teamId,
        },
        production: true, // Always production for prod function
      });

      // Create notification
      console.log("🏭 PROD: Creating APNs notification object...");
      const notification = new apn.Notification();

      const alertTitle = title || "Thanks for checking my work out!";
      const alertBody = body || "Don't forget to add my email or LinkedIn!";

      // Add unique identifier to prevent iOS deduplication
      // Generate proper UUID format for APNs notification ID
      const uniqueId = require("crypto").randomUUID();
      console.log("🏭 PROD: Creating unique notification UUID:", uniqueId);

      console.log("🏭 PROD: Setting notification content:",
          `title="${alertTitle}", body="${alertBody}"`);
      notification.alert = {
        title: alertTitle,
        body: alertBody,
      };
      notification.sound = "default";
      notification.topic = bundleId;
      notification.id = uniqueId; // Unique notification ID
      notification.payload = {
        notificationId: uniqueId,
        timestamp: Date.now(),
      }; // Prevent duplicate

      // Wait before sending notification
      const delayMs = Number(seconds) * 1000;
      console.log(`🏭 PROD: Waiting ${delayMs}ms before sending...`);
      await new Promise((r) => setTimeout(r, delayMs));

      // Send notification to production
      console.log("🏭 PROD: Sending push notification to production...");
      const result = await apnProvider.send(notification, token);
      console.log("🏭 PROD: Production APNs response:",
          JSON.stringify(result, null, 2));

      apnProvider.shutdown();

      if (result.sent && result.sent.length > 0) {
        console.log("🏭 PROD: Push notification sent successfully!");

        // Log simple analytics event for notification
        try {
          const {ownerId, deviceId, visitorName} = req.body || {};
          if (ownerId && deviceId) {
            console.log("📊 PROD: Logging notification_sent event");

            // Simple HTTP call to existing logClipEvent function
            const logUrl = "https://us-central1-cardinalapp-4279c.cloudfunctions.net/logClipEvent";
            const logBody = {
              ownerId: ownerId,
              deviceId: deviceId,
              visitorName: visitorName || "anonymous",
              action: "notification_sent",
              meta: {environment: "production"},
            };

            fetch(logUrl, {
              method: "POST",
              headers: {"Content-Type": "application/json"},
              body: JSON.stringify(logBody),
            }).catch((err) =>
              console.error("📊 PROD: Log request failed:", err));
          }
        } catch (logError) {
          console.error("📊 PROD: Failed to log notification event:", logError);
        }

        return res.json({
          ok: true,
          environment: "production",
          sent: result.sent.length,
          failed: result.failed.length,
        });
      } else {
        console.error("🏭 PROD: Push notification failed:", result.failed[0]);
        return res.status(500).json({
          error: "push notification failed",
          environment: "production",
          details: result.failed[0],
        });
      }
    } catch (e) {
      console.error("scheduleClipPush error:", e);
      return res.status(500).json({error: "internal server error"});
    }
  });
});
