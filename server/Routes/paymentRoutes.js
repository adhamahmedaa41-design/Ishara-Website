const express = require("express");
const router = express.Router();

const Order = require("../models/Order");
const Product = require("../models/Product");
const Cart = require("../models/Cart");
const stripeSvc = require("../services/stripeService");
const { sendOrderConfirmation } = require("../services/mailService");

// Stripe webhook — MUST receive raw body (mounted with express.raw in index.js).
router.post("/stripe/webhook", async (req, res) => {
    if (!stripeSvc.isEnabled()) {
        return res.status(503).json({ message: "Stripe not configured" });
    }
    const stripe = stripeSvc.getStripe();
    const sig = req.headers["stripe-signature"];
    const whSecret = process.env.STRIPE_WEBHOOK_SECRET;

    let event;
    try {
        event = stripe.webhooks.constructEvent(req.body, sig, whSecret);
    } catch (err) {
        console.error("Stripe webhook signature error:", err.message);
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    try {
        if (event.type === "payment_intent.succeeded") {
            const pi = event.data.object;
            const order = await Order.findOne({ paymentIntentId: pi.id });
            if (order && order.status === "pending_payment") {
                order.status = "paid";
                order.paidAt = new Date();
                await order.save();

                await Promise.all(
                    order.items.map((i) =>
                        Product.updateOne(
                            { _id: i.product, stock: { $gte: i.qty } },
                            { $inc: { stock: -i.qty } }
                        )
                    )
                );
                await Cart.findOneAndUpdate(
                    { user: order.user },
                    { $set: { items: [] } }
                );
                sendOrderConfirmation(order).catch(() => {});
            }
        } else if (event.type === "payment_intent.payment_failed") {
            const pi = event.data.object;
            await Order.updateOne(
                { paymentIntentId: pi.id, status: "pending_payment" },
                { $set: { status: "cancelled" } }
            );
        }
        res.json({ received: true });
    } catch (err) {
        console.error("Stripe webhook handler error:", err);
        res.status(500).json({ message: "Webhook processing failed" });
    }
});

module.exports = router;
