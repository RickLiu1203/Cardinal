const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const cors = require("cors")({origin: true});

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
