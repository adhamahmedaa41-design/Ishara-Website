// emailTemplates.js
// Professional HTML email templates for Ishara.
// ─────────────────────────────────────────────
// Swap BRAND_* constants below to match your brand.

const BRAND_NAME = "Ishara";
const BRAND_COLOR = "#0066cc";
const BRAND_DARK = "#004a99";
const BRAND_LIGHT = "#e6f0ff";
const LOGO_URL = "https://i.postimg.cc/k45Z8mDv/logo-small.png";

// ── Base layout wrapper ──────────────────────────────────────────────

function baseLayout(bodyContent) {
    return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>${BRAND_NAME}</title>
</head>
<body style="margin:0;padding:0;background-color:#f4f4f7;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f4f7;">
<tr><td align="center" style="padding:40px 16px;">

<!-- Container -->
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.07);">

<!-- Header -->
<tr>
<td style="background:linear-gradient(135deg,${BRAND_COLOR},${BRAND_DARK});padding:20px 32px;text-align:center;">
<img src="${LOGO_URL}" alt="${BRAND_NAME}" width="160" style="display:block;margin:0 auto;max-height:80px;object-fit:contain;">
</td>
</tr>

<!-- Body -->
<tr>
<td style="padding:32px 32px 24px;">
${bodyContent}
</td>
</tr>

<!-- Footer -->
<tr>
<td style="padding:20px 32px 28px;border-top:1px solid #eaeaea;text-align:center;">
<p style="margin:0 0 6px;font-size:12px;color:#999;">&copy; ${new Date().getFullYear()} ${BRAND_NAME}. All rights reserved.</p>
<p style="margin:0;font-size:12px;color:#999;">This is an automated message &mdash; please do not reply directly.</p>
</td>
</tr>

</table>
<!-- /Container -->

</td></tr>
</table>
</body>
</html>`;
}

// ── OTP verification email ───────────────────────────────────────────

function otpEmail({ name, otp, expiryMinutes = 10 }) {
    const greeting = name ? `Hi ${name},` : "Hi there,";

    const body = `
<p style="margin:0 0 16px;font-size:15px;color:#333;line-height:1.6;">${greeting}</p>
<p style="margin:0 0 24px;font-size:15px;color:#333;line-height:1.6;">Use the verification code below to complete your sign-in. This code is valid for <strong>${expiryMinutes} minutes</strong>.</p>

<!-- OTP Box -->
<div style="text-align:center;margin:0 0 24px;">
<div style="display:inline-block;background-color:${BRAND_LIGHT};border:2px dashed ${BRAND_COLOR};border-radius:10px;padding:16px 36px;">
<span style="font-family:'Courier New',Courier,monospace;font-size:34px;font-weight:700;letter-spacing:8px;color:${BRAND_DARK};">${otp}</span>
</div>
</div>

<p style="margin:0 0 8px;font-size:13px;color:#666;line-height:1.5;">If you did not request this code, you can safely ignore this email. Someone may have entered your email address by mistake.</p>

<!-- Security reminder -->
<div style="background-color:#fff8e1;border-left:4px solid #f9a825;border-radius:4px;padding:12px 16px;margin:20px 0 0;">
<p style="margin:0;font-size:13px;color:#795548;line-height:1.5;"><strong>Security tip:</strong> We will never ask you to share your verification code by phone, text, or email. Never share this code with anyone.</p>
</div>`;

    return {
        subject: `${otp} is your ${BRAND_NAME} verification code`,
        text: `${greeting}\n\nYour verification code is: ${otp}\n\nThis code is valid for ${expiryMinutes} minutes.\n\nIf you did not request this code, please ignore this email.\n\nSecurity tip: We will never ask you to share your verification code. Never share it with anyone.\n\n- The ${BRAND_NAME} Team`,
        html: baseLayout(body),
    };
}

// ── Password reset email ─────────────────────────────────────────────

function resetPasswordEmail({ name, resetUrl, expiryMinutes = 60 }) {
    const greeting = name ? `Hi ${name},` : "Hi there,";

    const body = `
<p style="margin:0 0 16px;font-size:15px;color:#333;line-height:1.6;">${greeting}</p>
<p style="margin:0 0 24px;font-size:15px;color:#333;line-height:1.6;">We received a request to reset the password for your ${BRAND_NAME} account. Click the button below to set a new password. This link is valid for <strong>${expiryMinutes} minutes</strong>.</p>

<!-- CTA Button -->
<div style="text-align:center;margin:0 0 28px;">
<a href="${resetUrl}" target="_blank" style="display:inline-block;background-color:${BRAND_COLOR};color:#ffffff;text-decoration:none;font-size:16px;font-weight:600;padding:14px 40px;border-radius:8px;letter-spacing:0.3px;">Reset Password</a>
</div>

<p style="margin:0 0 8px;font-size:13px;color:#666;line-height:1.5;">If the button above doesn't work, copy and paste this link into your browser:</p>
<p style="margin:0 0 20px;font-size:13px;color:${BRAND_COLOR};word-break:break-all;line-height:1.5;">${resetUrl}</p>

<p style="margin:0 0 8px;font-size:13px;color:#666;line-height:1.5;">If you didn't request a password reset, no action is needed &mdash; your account is safe and this link will expire automatically.</p>

<!-- Security reminder -->
<div style="background-color:#fff8e1;border-left:4px solid #f9a825;border-radius:4px;padding:12px 16px;margin:20px 0 0;">
<p style="margin:0;font-size:13px;color:#795548;line-height:1.5;"><strong>Security tip:</strong> ${BRAND_NAME} will never send you an email asking for your password. If you suspect unauthorized activity, change your password immediately.</p>
</div>`;

    return {
        subject: `Reset your ${BRAND_NAME} password`,
        text: `${greeting}\n\nWe received a request to reset your password.\n\nClick the link below to set a new password (valid for ${expiryMinutes} minutes):\n${resetUrl}\n\nIf you didn't request this, you can safely ignore this email.\n\n- The ${BRAND_NAME} Team`,
        html: baseLayout(body),
    };
}

// ── Contact form notification email ──────────────────────────────────

function contactNotificationEmail({ senderName, senderEmail, subject, message }) {
    const escapedEmail = senderEmail.replace(/</g, "&lt;").replace(/>/g, "&gt;");
    const escapedMessage = message.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/\n/g, "<br>");

    const body = `
<p style="margin:0 0 16px;font-size:15px;color:#333;line-height:1.6;">You received a new contact form submission:</p>

<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:0 0 20px;">
<tr>
<td style="padding:8px 0;font-size:13px;color:#666;width:80px;vertical-align:top;"><strong>From:</strong></td>
<td style="padding:8px 0;font-size:14px;color:#333;">${senderName} &lt;${escapedEmail}&gt;</td>
</tr>
<tr>
<td style="padding:8px 0;font-size:13px;color:#666;vertical-align:top;"><strong>Subject:</strong></td>
<td style="padding:8px 0;font-size:14px;color:#333;">${subject}</td>
</tr>
</table>

<div style="background-color:#f9f9f9;border-left:4px solid ${BRAND_COLOR};border-radius:4px;padding:16px;margin:0 0 16px;">
<p style="margin:0;font-size:14px;color:#333;line-height:1.6;">${escapedMessage}</p>
</div>

<p style="margin:0;font-size:13px;color:#666;">Reply directly to <a href="mailto:${senderEmail}" style="color:${BRAND_COLOR};">${senderEmail}</a> to respond.</p>`;

    return {
        subject: `New Contact: ${subject}`,
        text: `New contact form submission\n\nFrom: ${senderName} <${senderEmail}>\nSubject: ${subject}\n\n${message}`,
        html: baseLayout(body),
    };
}

module.exports = { otpEmail, resetPasswordEmail, contactNotificationEmail, baseLayout, BRAND_NAME };
