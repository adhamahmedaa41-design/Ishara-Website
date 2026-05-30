// services/mailService.js
// Order-confirmation email. Uses the existing Nodemailer transporter via
// utils/sendEmail.js — so Gmail config in .env "just works".
const sendEmail = require("../utils/sendEmail");

function fmtEGP(n) {
    return new Intl.NumberFormat("en-EG", {
        style: "currency",
        currency: "EGP",
        maximumFractionDigits: 0,
    }).format(Number(n) || 0);
}

function buildHtml(order) {
    const orderNum = String(order._id).slice(-6).toUpperCase();
    const rows = order.items
        .map(
            (i) => `
      <tr>
        <td style="padding:14px 10px;border-bottom:1px solid #eee;">
          ${i.image ? `<img src="${i.image}" alt="" width="48" height="48" style="border-radius:8px;vertical-align:middle;margin-right:10px;object-fit:cover;"/>` : ''}
          <strong>${i.titleEn}</strong><br/>
          <span style="color:#64748b;font-size:12px;">${i.titleAr || ""}</span>
        </td>
        <td style="padding:14px 10px;border-bottom:1px solid #eee;text-align:center;font-weight:500;">${i.qty}</td>
        <td style="padding:14px 10px;border-bottom:1px solid #eee;text-align:right;font-weight:600;">
          ${fmtEGP(i.unitPriceEGP * i.qty)}
        </td>
      </tr>`
        )
        .join("");

    return `
    <div style="font-family:'Segoe UI',Roboto,Arial,sans-serif;background:#f8fafc;padding:24px;">
      <div style="max-width:640px;margin:0 auto;background:#fff;border-radius:16px;overflow:hidden;border:1px solid #e2e8f0;box-shadow:0 4px 24px rgba(0,0,0,0.06);">
        <!-- Gradient Header -->
        <div style="background:linear-gradient(135deg,#14B8A6 0%,#0d9488 40%,#F97316 100%);padding:32px 24px;color:#fff;text-align:center;">
          <div style="width:64px;height:64px;background:rgba(255,255,255,0.2);border-radius:50%;margin:0 auto 16px;display:flex;align-items:center;justify-content:center;">
            <span style="font-size:32px;">✓</span>
          </div>
          <h1 style="margin:0;font-size:26px;font-weight:700;letter-spacing:0.5px;">Payment Successful!</h1>
          <p style="margin:8px 0 0;opacity:.9;font-size:15px;">Thank you for your purchase</p>
          <p style="margin:4px 0 0;opacity:.8;font-size:13px;">شكراً لطلبك من إشارة</p>
        </div>

        <div style="padding:28px 24px;color:#0f172a;">
          <!-- Order badge -->
          <div style="text-align:center;margin-bottom:24px;">
            <span style="display:inline-block;padding:8px 20px;background:#f0fdf4;border:1px solid #bbf7d0;border-radius:999px;color:#15803d;font-size:14px;font-weight:600;">Order #${orderNum} — Confirmed</span>
          </div>

          <p style="margin:0 0 20px;font-size:15px;line-height:1.6;">Hi <strong>${order.address.fullName}</strong>,</p>
          <p style="margin:0 0 20px;font-size:15px;line-height:1.6;color:#475569;">Your order has been successfully processed and confirmed. Below is a summary of your purchase:</p>

          <!-- Items table -->
          <table style="width:100%;border-collapse:collapse;margin-top:8px;">
            <thead>
              <tr style="background:#f1f5f9;">
                <th style="padding:12px 10px;text-align:left;font-size:13px;text-transform:uppercase;letter-spacing:0.5px;color:#64748b;font-weight:600;">Item</th>
                <th style="padding:12px 10px;text-align:center;font-size:13px;text-transform:uppercase;letter-spacing:0.5px;color:#64748b;font-weight:600;">Qty</th>
                <th style="padding:12px 10px;text-align:right;font-size:13px;text-transform:uppercase;letter-spacing:0.5px;color:#64748b;font-weight:600;">Total</th>
              </tr>
            </thead>
            <tbody>${rows}</tbody>
          </table>

          <!-- Totals -->
          <div style="margin-top:20px;background:#f8fafc;border-radius:12px;padding:16px;">
            <div style="display:flex;justify-content:space-between;margin-bottom:8px;"><span style="color:#64748b;">Subtotal</span> <strong>${fmtEGP(order.subtotalEGP)}</strong></div>
            <div style="display:flex;justify-content:space-between;margin-bottom:8px;"><span style="color:#64748b;">Shipping</span> <strong>${fmtEGP(order.shippingEGP)}</strong></div>
            <hr style="border:none;border-top:1px solid #e2e8f0;margin:12px 0;"/>
            <div style="display:flex;justify-content:space-between;font-size:18px;">
              <span style="font-weight:700;">Total</span>
              <span style="font-weight:700;color:#14B8A6;">${fmtEGP(order.totalEGP)}</span>
            </div>
          </div>

          <hr style="border:none;border-top:1px solid #e2e8f0;margin:28px 0;"/>

          <!-- Shipping -->
          <h3 style="margin:0 0 10px;font-size:15px;color:#0f172a;">📦 Shipping to</h3>
          <p style="margin:0;color:#475569;font-size:14px;line-height:1.7;">
            ${order.address.fullName}<br/>
            ${order.address.line1}${order.address.line2 ? ", " + order.address.line2 : ""}<br/>
            ${order.address.city}, ${order.address.governorate} ${order.address.postalCode || ""}<br/>
            📞 ${order.address.phone}
          </p>

          <!-- Success banner -->
          <div style="margin-top:28px;background:linear-gradient(135deg,rgba(20,184,166,0.08),rgba(249,115,22,0.08));border:1px solid rgba(20,184,166,0.2);border-radius:12px;padding:16px;text-align:center;">
            <p style="margin:0;font-size:14px;color:#14B8A6;font-weight:600;">🎉 Your order is on its way!</p>
            <p style="margin:6px 0 0;font-size:13px;color:#475569;">We'll notify you with tracking updates.</p>
          </div>

          <p style="color:#94a3b8;margin-top:24px;font-size:12px;text-align:center;">
            Need help? Reply to this email and our team will be with you shortly.
          </p>
        </div>
      </div>
    </div>`;
}

async function sendOrderConfirmation(order) {
    const orderNum = String(order._id).slice(-6).toUpperCase();
    const html = buildHtml(order);
    const subject = `✅ ISHARA — Order #${orderNum} Payment Successful!`;
    const itemsList = order.items
        .map((i) => `  • ${i.titleEn} × ${i.qty} — ${fmtEGP(i.unitPriceEGP * i.qty)}`)
        .join("\n");
    const text = [
        `Payment Successful! 🎉`,
        ``,
        `Hi ${order.address.fullName},`,
        ``,
        `Your ISHARA order #${orderNum} has been confirmed.`,
        ``,
        `Items purchased:`,
        itemsList,
        ``,
        `Subtotal: ${fmtEGP(order.subtotalEGP)}`,
        `Shipping: ${fmtEGP(order.shippingEGP)}`,
        `Total: ${fmtEGP(order.totalEGP)}`,
        ``,
        `Shipping to: ${order.address.line1}, ${order.address.city}, ${order.address.governorate}`,
        ``,
        `We'll be in touch with shipping updates.`,
        `— The ISHARA Team`,
    ].join("\n");
    try {
        await sendEmail(order.receiptEmail, subject, text, html);
        console.log(`Order confirmation email sent for order #${orderNum} to ${order.receiptEmail}`);
    } catch (err) {
        // Don't fail the order if email fails — just log.
        console.error(`Order confirmation email FAILED for #${orderNum}:`, err.message);
    }
}

module.exports = { sendOrderConfirmation };
