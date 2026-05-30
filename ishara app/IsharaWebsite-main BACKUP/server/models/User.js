// models/User.js
const mongoose = require("mongoose");

const UserSchema = new mongoose.Schema(
    {
        // authentication
        email: { type: String, required: true, unique: true },
        password: { type: String, required: true },
        role: { type: String, enum: ["user", "admin", "supplier"], default: "user" },
        isVerified: { type: Boolean, default: false },
        otp: { type: String, maxlength: 6 },
        otpExpiry: { type: Date },
        resetPasswordToken: { type: String },
        resetPasswordExpiry: { type: Date },

        // profile - FIX: Changed 'profilepic' to 'profilePic' (camelCase consistency)
        name: { type: String, required: true },
        profilePic: { type: String, default: "" }, // Set dynamically in register handler via ui-avatars.com
        bio: { type: String, default: "" },

        // Ishara-specific fields
        disabilityType: {
            type: String,
            enum: ["deaf", "non-verbal", "blind", "hearing"],
            required: true,
            default: "hearing",
        },
        emergencyContacts: [
            {
                name: String,
                phone: String,
                email: { type: String, default: "" },
                relationship: { type: String, default: "" },
                app: { type: String, default: "all" },
                priority: { type: Number, default: 0 },
                telegramChatId: { type: String, default: "" },
            },
        ],
        preferences: {
            type: Map,
            of: mongoose.Schema.Types.Mixed,
            default: () =>
                new Map([
                    ["vibrationLevel", 3],
                    ["fontSize", "medium"],
                    ["highContrast", false],
                    ["ttsVoice", "default"],
                ]),
        },

        // Learning progress: keyed by lessonId
        // e.g. { "lesson_family": { watched: true, quizPassed: true } }
        learningProgress: {
            type: Map,
            of: new mongoose.Schema(
                { watched: { type: Boolean, default: false }, quizPassed: { type: Boolean, default: false } },
                { _id: false }
            ),
            default: () => new Map(),
        },

        // Activity dates for streak tracking (yyyy-MM-dd strings)
        learningActivityDates: {
            type: [String],
            default: [],
        },
    },
    { timestamps: true }
);

// Prevent model overwrite error
const User = mongoose.models.User || mongoose.model("User", UserSchema);

module.exports = User;
