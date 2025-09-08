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

      // Return the same structure your App Clip expects
      return res.json({
        firstName: data.firstName || "",
        lastName: data.lastName || "",
        email: data.email || "",
        linkedIn: data.linkedIn || "",
      });
    } catch (error) {
      console.error("Error fetching portfolio:", error);
      return res.status(500).json({error: "internal server error"});
    }
  });
});
