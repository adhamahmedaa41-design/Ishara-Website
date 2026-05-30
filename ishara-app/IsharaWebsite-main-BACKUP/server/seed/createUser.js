require("dotenv").config({ path: require("path").join(__dirname, "..", ".env") });
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

async function run() {
  await mongoose.connect(process.env.CONNECTION_STRING);
  const db = mongoose.connection.db;

  const email = "adhamahmed.aa41@gmail.com";
  const password = "adham2412";
  const name = "Adham Ahmed";

  const hash = await bcrypt.hash(password, 12);

  // Upsert — create if missing, update if exists
  await db.collection("users").updateOne(
    { email },
    {
      $set: {
        email,
        password: hash,
        name,
        isVerified: true,
        role: "user",
        profilePic: `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=14B8A6&color=fff&size=128&bold=true`,
      },
      $setOnInsert: {
        createdAt: new Date(),
        disabilityType: "none",
        emergencyContacts: [],
        preferences: {},
      },
    },
    { upsert: true }
  );

  console.log(`✅ User ready: ${email} / ${password}`);
  process.exit(0);
}

run().catch((e) => { console.error(e); process.exit(1); });
