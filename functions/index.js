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

      // Also load text blocks and experiences
      const itemsSnap = await admin.firestore()
          .collection("users").doc(id)
          .collection("sections").doc("textBlocks")
          .collection("items")
          .orderBy("createdAt", "asc")
          .get();
      const textBlocks = itemsSnap.docs.map((d) => {
        const td = d.data() || {};
        return {
          id: d.id,
          header: td.header || "",
          body: td.body || "",
        };
      });

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

      // Return the structure the App Clip expects
      return res.json({
        firstName: data.firstName || "",
        lastName: data.lastName || "",
        email: data.email || "",
        linkedIn: data.linkedIn || "",
        phoneNumber: data.phoneNumber || "",
        github: data.github || "",
        website: data.website || "",
        textBlocks,
        experiences,
        resume,
        skills,
        projects,
      });
    } catch (error) {
      console.error("Error fetching portfolio:", error);
      return res.status(500).json({error: "internal server error"});
    }
  });
});
