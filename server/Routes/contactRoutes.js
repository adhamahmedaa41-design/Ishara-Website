const express = require("express");
const router = express.Router();
const Joi = require("joi");
const ContactMessage = require("../models/ContactMessage");
const sendEmail = require("../utils/sendEmail");
const { contactNotificationEmail } = require("../utils/emailTemplates");

const contactSchema = Joi.object({
    name: Joi.string().min(2).max(100).required(),
    email: Joi.string().email().required(),
    subject: Joi.string().min(2).max(200).required(),
    message: Joi.string().min(5).max(5000).required(),
});

// POST /api/contact
router.post("/", async (req, res) => {
    try {
        const { error, value } = contactSchema.validate(req.body, {
            abortEarly: false,
        });

        if (error) {
            return res.status(400).json({
                message: "Validation failed",
                errors: error.details.map((d) => d.message),
            });
        }

        const { name, email, subject, message } = value;

        // Save to database
        const contactMsg = await ContactMessage.create({
            name,
            email,
            subject,
            message,
        });

        // Send notification email (optional – won't fail the request)
        try {
            const tpl = contactNotificationEmail({
                senderName: name,
                senderEmail: email,
                subject,
                message,
            });
            await sendEmail(process.env.EMAIL_USER, tpl.subject, tpl.text, tpl.html);
        } catch (emailErr) {
            console.warn("Contact notification email failed:", emailErr.message);
        }

        return res.status(201).json({
            success: true,
            message: "Message received! We'll get back to you soon.",
        });
    } catch (error) {
        console.error("Contact form error:", error);
        return res.status(500).json({ message: "Internal server error" });
    }
});

module.exports = router;
