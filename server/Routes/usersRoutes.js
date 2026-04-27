const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const User = require("../models/User");

// FIX: Import authMiddleware correctly - it exports { authMiddleware }
const { authMiddleware } = require("../middleware/authMiddleware");

const uploadsDir = "./uploads";
if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, uploadsDir);
    },
    filename: function (req, file, cb) {
        const userId = req.user.id;
        const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
        const ext = path.extname(file.originalname);
        cb(null, `profile-${userId}-${uniqueSuffix}${ext}`);
    },
});

const fileFilter = (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const extname = allowedTypes.test(
        path.extname(file.originalname).toLowerCase()
    );
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
        return cb(null, true);
    } else {
        cb(new Error("Only image files (jpeg, jpg, png, gif) are allowed"));
    }
};

const upload = multer({
    storage: storage,
    limits: { fileSize: 2 * 1024 * 1024 },
    fileFilter: fileFilter,
});

// PUT /api/users/update-avatar
router.put(
    "/update-avatar",
    authMiddleware, // Now this is a function, not an object
    upload.single("avatar"),
    async (req, res) => {
        try {
            const user = await User.findById(req.user.id);

            if (!user) {
                return res.status(404).json({
                    success: false,
                    message: "User not found",
                });
            }

            if (!req.file) {
                return res.status(400).json({
                    success: false,
                    message: "No avatar file uploaded",
                });
            }

            const avatarPath = `/uploads/${req.file.filename}`;
            user.profilePic = avatarPath;
            await user.save();

            const userResponse = {
                id: user._id,
                email: user.email,
                name: user.name,
                role: user.role,
                isVerified: user.isVerified,
                profilePic: user.profilePic,
                bio: user.bio,
                disabilityType: user.disabilityType,
                emergencyContacts: user.emergencyContacts,
                preferences: user.preferences,
            };

            return res.json({
                success: true,
                message: "Profile picture updated successfully",
                avatar: avatarPath,
                user: userResponse,
            });
        } catch (error) {
            console.error("Avatar update error:", error);

            if (error.code === "LIMIT_FILE_SIZE") {
                return res.status(400).json({
                    success: false,
                    message: "File too large. Maximum size is 2MB",
                });
            }

            if (error.message.includes("Only image files")) {
                return res.status(400).json({
                    success: false,
                    message: "Only image files (jpeg, jpg, png, gif) are allowed",
                });
            }

            return res.status(500).json({
                success: false,
                message: "Server error while updating profile picture",
                error: error.message,
            });
        }
    }
);

// PUT /api/users/update-profile
router.put("/update-profile", authMiddleware, async (req, res) => {
    try {
        const { name, bio, disabilityType, emergencyContacts, preferences } = req.body;

        if (!name && !bio && !disabilityType && !emergencyContacts && !preferences) {
            return res.status(400).json({
                success: false,
                message: "At least one field (name, bio, disabilityType, emergencyContacts, or preferences) must be provided",
            });
        }

        const user = await User.findById(req.user.id);

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found",
            });
        }

        if (name !== undefined) user.name = name;
        if (bio !== undefined) user.bio = bio;
        if (disabilityType !== undefined) user.disabilityType = disabilityType;
        if (emergencyContacts !== undefined) user.emergencyContacts = emergencyContacts; // replace whole array
        if (preferences !== undefined) {
            // Replace preferences map entries
            for (const [key, val] of Object.entries(preferences)) {
                user.preferences.set(key, val);
            }
        }

        await user.save();

        const userResponse = {
            id: user._id,
            email: user.email,
            name: user.name,
            role: user.role,
            isVerified: user.isVerified,
            profilePic: user.profilePic,
            bio: user.bio,
            disabilityType: user.disabilityType,
            emergencyContacts: user.emergencyContacts,
            preferences: user.preferences,
        };

        return res.json({
            success: true,
            message: "Profile updated successfully",
            user: userResponse,
        });
    } catch (error) {
        console.error("Profile update error:", error);
        return res.status(500).json({
            success: false,
            message: "Server error while updating profile",
            error: error.message,
        });
    }
});

// GET /api/users/profile
router.get("/profile", authMiddleware, async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select(
            "-password -otp -otpExpiry -resetPasswordToken -resetPasswordExpiry"
        );

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found",
            });
        }

        return res.json({
            success: true,
            user: {
                id: user._id,
                email: user.email,
                name: user.name,
                role: user.role,
                isVerified: user.isVerified,
                profilePic: user.profilePic,
                bio: user.bio,
                disabilityType: user.disabilityType,
                emergencyContacts: user.emergencyContacts,
                preferences: user.preferences,
            },
        });
    } catch (error) {
        console.error("Get profile error:", error);
        return res.status(500).json({
            success: false,
            message: "Server error while fetching profile",
            error: error.message,
        });
    }
});

// GET /api/users/profile/:userId - Public profile view
router.get("/profile/:userId", async (req, res) => {
    try {
        const user = await User.findById(req.params.userId).select(
            "name bio profilePic disabilityType"
        );

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "User not found",
            });
        }

        return res.json({
            success: true,
            user: {
                id: user._id,
                name: user.name,
                bio: user.bio,
                profilePic: user.profilePic,
                disabilityType: user.disabilityType,
            },
        });
    } catch (error) {
        console.error("Get public profile error:", error);
        return res.status(500).json({
            success: false,
            message: "Server error while fetching profile",
            error: error.message,
        });
    }
});

// ─── Emergency contacts CRUD (used by the Flutter app) ────────────────────
//
// All endpoints below operate on the authenticated user's
// `emergencyContacts` array. Each contact is returned with both `_id`
// (Mongo) and `id` (string) for client compatibility.

function _mapContact(c) {
    return {
        id: c._id ? c._id.toString() : "",
        _id: c._id ? c._id.toString() : "",
        name: c.name || "",
        phone: c.phone || "",
        email: c.email || "",
        relationship: c.relationship || "",
        app: c.app || "all",
        priority: typeof c.priority === "number" ? c.priority : 0,
        telegramChatId: c.telegramChatId || "",
    };
}

// GET /api/users/emergency-contacts
router.get("/emergency-contacts", authMiddleware, async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select("emergencyContacts");
        if (!user) {
            return res.status(404).json({ success: false, message: "User not found" });
        }
        return res.json({
            success: true,
            contacts: (user.emergencyContacts || []).map(_mapContact),
        });
    } catch (error) {
        console.error("List emergency contacts error:", error);
        return res.status(500).json({ success: false, message: "Server error" });
    }
});

// POST /api/users/emergency-contacts
router.post("/emergency-contacts", authMiddleware, async (req, res) => {
    try {
        const { name, phone, email, relationship, app, priority, telegramChatId } = req.body;
        if (!name || !phone) {
            return res.status(400).json({ success: false, message: "name and phone are required" });
        }
        const user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({ success: false, message: "User not found" });
        }
        const contact = {
            name,
            phone,
            email: email || "",
            relationship: relationship || "",
            app: app || "all",
            priority: typeof priority === "number" ? priority : 0,
            telegramChatId: telegramChatId || "",
        };
        user.emergencyContacts.push(contact);
        await user.save();
        const created = user.emergencyContacts[user.emergencyContacts.length - 1];
        return res.json({ success: true, contact: _mapContact(created) });
    } catch (error) {
        console.error("Add emergency contact error:", error);
        return res.status(500).json({ success: false, message: "Server error" });
    }
});

// PUT /api/users/emergency-contacts/:id
router.put("/emergency-contacts/:id", authMiddleware, async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({ success: false, message: "User not found" });
        }
        const c = user.emergencyContacts.id(req.params.id);
        if (!c) {
            return res.status(404).json({ success: false, message: "Contact not found" });
        }
        const { name, phone, email, relationship, app, priority, telegramChatId } = req.body;
        if (name !== undefined) c.name = name;
        if (phone !== undefined) c.phone = phone;
        if (email !== undefined) c.email = email;
        if (relationship !== undefined) c.relationship = relationship;
        if (app !== undefined) c.app = app;
        if (priority !== undefined) c.priority = priority;
        if (telegramChatId !== undefined) c.telegramChatId = telegramChatId;
        await user.save();
        return res.json({ success: true, contact: _mapContact(c) });
    } catch (error) {
        console.error("Update emergency contact error:", error);
        return res.status(500).json({ success: false, message: "Server error" });
    }
});

// DELETE /api/users/emergency-contacts/:id
router.delete("/emergency-contacts/:id", authMiddleware, async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        if (!user) {
            return res.status(404).json({ success: false, message: "User not found" });
        }
        const before = user.emergencyContacts.length;
        user.emergencyContacts = user.emergencyContacts.filter(
            (c) => c._id.toString() !== req.params.id,
        );
        if (user.emergencyContacts.length === before) {
            return res.status(404).json({ success: false, message: "Contact not found" });
        }
        await user.save();
        return res.json({ success: true });
    } catch (error) {
        console.error("Delete emergency contact error:", error);
        return res.status(500).json({ success: false, message: "Server error" });
    }
});

// ─── Learning progress ─────────────────────────────────────────────────────

// GET /api/users/learning-progress
router.get("/learning-progress", authMiddleware, async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select("learningProgress learningActivityDates");
        if (!user) return res.status(404).json({ success: false, message: "User not found" });

        const progress = {};
        if (user.learningProgress) {
            for (const [k, v] of user.learningProgress.entries()) {
                progress[k] = { watched: v.watched || false, quizPassed: v.quizPassed || false };
            }
        }

        return res.json({
            success: true,
            progress,
            activityDates: user.learningActivityDates || [],
        });
    } catch (err) {
        console.error("Get learning progress error:", err);
        return res.status(500).json({ success: false, message: "Server error" });
    }
});

// PUT /api/users/learning-progress
// Body: { progress: { lessonId: { watched, quizPassed } }, activityDates: ["yyyy-MM-dd"] }
router.put("/learning-progress", authMiddleware, async (req, res) => {
    try {
        const { progress, activityDates } = req.body;
        const user = await User.findById(req.user.id);
        if (!user) return res.status(404).json({ success: false, message: "User not found" });

        if (progress && typeof progress === "object") {
            for (const [lessonId, val] of Object.entries(progress)) {
                const existing = user.learningProgress.get(lessonId) || {};
                user.learningProgress.set(lessonId, {
                    watched: val.watched ?? existing.watched ?? false,
                    quizPassed: val.quizPassed ?? existing.quizPassed ?? false,
                });
            }
        }

        if (Array.isArray(activityDates)) {
            const merged = new Set([...(user.learningActivityDates || []), ...activityDates]);
            user.learningActivityDates = [...merged];
        }

        user.markModified("learningProgress");
        await user.save();

        const saved = {};
        for (const [k, v] of user.learningProgress.entries()) {
            saved[k] = { watched: v.watched || false, quizPassed: v.quizPassed || false };
        }

        return res.json({
            success: true,
            progress: saved,
            activityDates: user.learningActivityDates,
        });
    } catch (err) {
        console.error("Update learning progress error:", err);
        return res.status(500).json({ success: false, message: "Server error" });
    }
});

module.exports = router;
