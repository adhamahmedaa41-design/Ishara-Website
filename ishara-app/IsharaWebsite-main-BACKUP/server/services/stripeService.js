// services/stripeService.js
// Lazy-init Stripe. If STRIPE_SECRET_KEY is missing we fall back to "mock"
// mode so the full checkout flow stays demoable without real merchant keys.
let stripeInstance = null;

function getStripe() {
    if (stripeInstance) return stripeInstance;
    const key = process.env.STRIPE_SECRET_KEY;
    if (!key) return null;
    // Lazy require so the server boots even if `stripe` npm pkg is missing in dev.
    // eslint-disable-next-line global-require
    const Stripe = require("stripe");
    stripeInstance = new Stripe(key, { apiVersion: "2024-11-20.acacia" });
    return stripeInstance;
}

function isEnabled() {
    return Boolean(process.env.STRIPE_SECRET_KEY);
}

module.exports = { getStripe, isEnabled };
