
const {initializeApp, applicationDefault} =
  require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");

initializeApp({
  credential: applicationDefault(),
  projectId: "homeassist-fyp-2026",
});

// eslint-disable-next-line require-jsdoc
async function main() {
  let pageToken;
  let updated = 0;
  let skipped = 0;

  do {
    const result = await getAuth().listUsers(
        1000, pageToken);

    for (const user of result.users) {
      const claims = user.customClaims || {};

      if (user.disabled ||
          (claims.role && claims.role !== "authenticated")) {
        console.log("Skipped user:", user.uid);
        skipped++;
        continue;
      }

      if (claims.role === "authenticated") {
        continue;
      }

      await getAuth().setCustomUserClaims(user.uid, {
        ...claims,
        role: "authenticated",
      });

      updated++;
    }

    pageToken = result.pageToken;
  } while (pageToken);

  console.log("Users updated:", updated);
  console.log("Users skipped:", skipped);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
