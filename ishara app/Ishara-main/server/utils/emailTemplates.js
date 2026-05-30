const BRAND_COLOR = "#0066cc";
const BRAND_DARK = "#004a99";
const LOGO_URL = "https://i.postimg.cc/k45Z8mDv/logo-small.png";

function baseLayout(bodyContent) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Ishara</title>
</head>
<body style="margin:0;padding:0;background-color:#f4f4f7;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f4f7;">
<tr><td align="center" style="padding:40px 16px;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background-color:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.07);">
<tr>
<td style="background:linear-gradient(135deg,${BRAND_COLOR},${BRAND_DARK});padding:20px 32px;text-align:center;">
<img src="${LOGO_URL}" alt="Ishara" width="160" style="display:block;margin:0 auto;max-height:80px;object-fit:contain;">
</td>
</tr>
<tr>
<td style="padding:32px 32px 24px;">
${bodyContent}
</td>
</tr>
<tr>
<td style="padding:20px 32px 28px;border-top:1px solid #eaeaea;text-align:center;">
<p style="margin:0 0 6px;font-size:12px;color:#999;">&copy; ${new Date().getFullYear()} Ishara. All rights reserved.</p>
<p style="margin:0;font-size:12px;color:#999;">This is an automated message &mdash; please do not reply directly.</p>
</td>
</tr>
</table>
</td></tr>
</table>
</body>
</html>`;
}

function otpEmail({ name, otp }) {
  const safeName = (name || "there").trim() || "there";

  const body = `
<p style="margin:0 0 16px;font-size:15px;color:#333;line-height:1.6;">Hello ${safeName},</p>
<p style="margin:0 0 24px;font-size:15px;color:#333;line-height:1.6;">Your OTP verification code is:</p>
<div style="text-align:center;margin:0 0 24px;">
<div style="display:inline-block;background-color:#e6f0ff;border:2px dashed ${BRAND_COLOR};border-radius:10px;padding:16px 36px;">
<span style="font-family:'Courier New',Courier,monospace;font-size:34px;font-weight:700;letter-spacing:8px;color:${BRAND_DARK};">${otp}</span>
</div>
</div>
<p style="margin:0 0 8px;font-size:13px;color:#666;line-height:1.5;">This code expires in <strong>10 minutes</strong>.</p>
<p style="margin:0;font-size:13px;color:#666;line-height:1.5;">If you did not request this, you can safely ignore this email.</p>`;

  return {
    subject: "Your Ishara verification code",
    text: `Hello ${safeName},\n\nYour OTP code is: ${otp}\nThis code expires in 10 minutes.\n\nIf you did not request this, please ignore this email.`,
    html: baseLayout(body),
  };
}

function resetPasswordEmail({ name, resetUrl }) {
  const safeName = (name || "there").trim() || "there";

  const body = `
<p style="margin:0 0 16px;font-size:15px;color:#333;line-height:1.6;">Hello ${safeName},</p>
<p style="margin:0 0 24px;font-size:15px;color:#333;line-height:1.6;">You requested to reset your Ishara password. Click the button below to set a new password. This link is valid for <strong>1 hour</strong>.</p>
<div style="text-align:center;margin:0 0 28px;">
<a href="${resetUrl}" target="_blank" style="display:inline-block;background-color:${BRAND_COLOR};color:#ffffff;text-decoration:none;font-size:16px;font-weight:600;padding:14px 40px;border-radius:8px;">Reset Password</a>
</div>
<p style="margin:0 0 8px;font-size:13px;color:#666;line-height:1.5;">If the button doesn't work, copy and paste this link into your browser:</p>
<p style="margin:0 0 16px;font-size:13px;color:${BRAND_COLOR};word-break:break-all;">${resetUrl}</p>
<p style="margin:0;font-size:13px;color:#666;line-height:1.5;">If you didn't request a password reset, no action is needed.</p>`;

  return {
    subject: "Reset your Ishara password",
    text: `Hello ${safeName},\n\nYou requested to reset your password.\nUse this link: ${resetUrl}\n\nThis link expires in 1 hour.\nIf you did not request a reset, please ignore this email.`,
    html: baseLayout(body),
  };
}

module.exports = {
  otpEmail,
  resetPasswordEmail,
};
