const express = require("express");
const rateLimit = require("express-rate-limit");
const router = express.Router();

const { validate } = require("../middleware/validate");
const { chatSchema } = require("../validation/chatSchemas");
const { streamReply } = require("../services/geminiService");

// Tight rate limit for the chat proxy — 30 messages / 5 min / IP.
const chatLimiter = rateLimit({
    windowMs: 5 * 60 * 1000,
    max: 30,
    standardHeaders: true,
    legacyHeaders: false,
    message: { message: "Too many messages. Please wait a moment." },
});

router.post("/", chatLimiter, validate(chatSchema), async (req, res) => {
    try {
        await streamReply(res, req.body);
    } catch (err) {
        console.error("Chat route error:", err);
        if (!res.headersSent) {
            res.status(500).json({ message: "Chat service unavailable" });
        } else {
            try {
                res.end();
            } catch {
                /* ignore */
            }
        }
    }
});

module.exports = router;
