// sosRoutes.js
// Emergency SOS dispatch — sends an email to one or more emergency contacts
// using the same Nodemailer transporter as the rest of the auth flow.
// Called from the Ishara mobile app's Safety screen.

const express = require("express");
const router = express.Router();
const Joi = require("joi");
const sendEmail = require("../utils/sendEmail");
const { baseLayout, BRAND_NAME } = require("../utils/emailTemplates");

// ── Validation ─────────────────────────────────────────────────────────────
const sosSchema = Joi.object({
    to: Joi.alternatives()
        .try(Joi.string().email(), Joi.array().items(Joi.string().email()).min(1))
        .required(),
    senderName: Joi.string().max(120).default("Ishara user"),
    senderPhone: Joi.string().max(40).allow(""),
    location: Joi.object({
        lat: Joi.number().required(),
        lng: Joi.number().required(),
    }).optional(),
});

// ── Email body ────────────────────────────────────────────────────────────
function buildSosEmail({ senderName, senderPhone, location }) {
    const mapsUrl = location
        ? `https://maps.google.com/?q=${location.lat},${location.lng}`
        : "";

    const text = [
        `🚨 SOS — ${senderName} needs urgent help.`,
        senderPhone ? `Phone: ${senderPhone}` : "",
        mapsUrl ? `Location: ${mapsUrl}` : "",
        "",
        "— sent automatically from the Ishara app.",
        "",
        `🚨 طلب استغاثة من ${senderName}.`,
        senderPhone ? `الهاتف: ${senderPhone}` : "",
        mapsUrl ? `الموقع: ${mapsUrl}` : "",
        "",
        "— مرسل تلقائياً من تطبيق إشارة.",
    ]
        .filter(Boolean)
        .join("\n");

    const body = `
        <div style="padding:32px;color:#1f2937;">
            <h1 style="color:#dc2626;font-size:28px;margin:0 0 12px;">🚨 SOS — Emergency</h1>
            <p style="font-size:16px;margin:0 0 8px;">
                <strong>${senderName}</strong> has triggered an emergency alert from the ${BRAND_NAME} app.
            </p>
            ${
                senderPhone
                    ? `<p style="font-size:14px;margin:8px 0;">📞 Phone: <a href="tel:${senderPhone}">${senderPhone}</a></p>`
                    : ""
            }
            ${
                mapsUrl
                    ? `<p style="font-size:14px;margin:16px 0;">
                            📍 <a href="${mapsUrl}" style="color:#0066cc;font-weight:600;">View live location on Google Maps</a>
                        </p>`
                    : ""
            }
            <hr style="margin:24px 0;border:none;border-top:1px solid #e5e7eb;">
            <p style="font-size:14px;color:#6b7280;margin:0;">
                Please reach out to ${senderName} as soon as possible.
            </p>
            <hr style="margin:24px 0;border:none;border-top:1px solid #e5e7eb;">
            <div dir="rtl" style="font-family:Tahoma,Arial,sans-serif;">
                <h2 style="color:#dc2626;font-size:22px;margin:0 0 8px;">🚨 طلب استغاثة</h2>
                <p style="font-size:15px;margin:0;">
                    أطلق <strong>${senderName}</strong> تنبيه طارئ من تطبيق ${BRAND_NAME}.
                </p>
                ${mapsUrl ? `<p style="font-size:14px;margin:12px 0;">📍 <a href="${mapsUrl}">عرض الموقع على الخرائط</a></p>` : ""}
                <p style="font-size:14px;color:#6b7280;margin:12px 0 0;">يرجى التواصل في أسرع وقت ممكن.</p>
            </div>
        </div>
    `;

    return {
        subject: `🚨 SOS from ${senderName} · طلب استغاثة`,
        text,
        html: baseLayout(body),
    };
}

// ── POST /api/sos ─────────────────────────────────────────────────────────
router.post("/", async (req, res) => {
    const { error, value } = sosSchema.validate(req.body, { abortEarly: false });
    if (error) {
        return res.status(400).json({
            message: "Validation failed",
            errors: error.details.map((d) => d.message),
        });
    }

    const recipients = Array.isArray(value.to) ? value.to : [value.to];
    const tpl = buildSosEmail(value);

    const results = await Promise.allSettled(
        recipients.map((to) => sendEmail(to, tpl.subject, tpl.text, tpl.html))
    );

    const sent = results.filter((r) => r.status === "fulfilled").length;
    const failed = results.length - sent;

    if (sent === 0) {
        return res.status(502).json({
            success: false,
            message: "Could not send any SOS emails. Please try again.",
            sent,
            failed,
        });
    }

    return res.status(200).json({
        success: true,
        message: `SOS sent to ${sent} contact${sent === 1 ? "" : "s"}.`,
        sent,
        failed,
    });
});

module.exports = router;
