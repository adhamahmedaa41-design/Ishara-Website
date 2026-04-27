// sendEmail.js
// Reusable email sender — uses Gmail SMTP via Nodemailer.
// To switch providers (SendGrid, Resend, etc.) later, only change the
// transporter creation below. The rest of the codebase stays untouched.
// ─────────────────────────────────────────────────────────────────────
require("dotenv").config();
const nodemailer = require("nodemailer");

const { BRAND_NAME } = require("./emailTemplates");

const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

/**
 * Send an email.
 *
 * @param {string}      to      Recipient address
 * @param {string}      subject Email subject line
 * @param {string}      text    Plain-text body (required for accessibility)
 * @param {string|null} html    Optional HTML body
 * @returns {Promise}
 */
async function sendEmail(to, subject, text, html = null) {
    try {
        const mailOptions = {
            from: `"${BRAND_NAME}" <${process.env.EMAIL_USER}>`,
            to,
            subject,
        };

        if (html) {
            mailOptions.html = html;
            mailOptions.text = text || html.replace(/<[^>]*>/g, "");
        } else {
            mailOptions.text = text;
        }

        const info = await transporter.sendMail(mailOptions);
        console.log("Email sent! Message ID:", info.messageId);
        return info;
    } catch (error) {
        console.error("Failed to send email:", error.message);
        throw error;
    }
}

module.exports = sendEmail;
