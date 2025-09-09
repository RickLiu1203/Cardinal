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
        return {
          id: d.id,
          company: ed.company || "",
          role: ed.role || "",
          startDate: ed.startDateString || null,
          endDate: ed.endDateString || null,
          description: ed.description || "",
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
