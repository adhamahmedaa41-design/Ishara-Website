const express = require("express");
const router = express.Router();

const Order = require("../models/Order");
const Product = require("../models/Product");
const Cart = require("../models/Cart");
const { authMiddleware } = require("../middleware/authMiddleware");
const { validate } = require("../middleware/validate");
const { createOrderSchema } = require("../validation/orderSchemas");
const stripeSvc = require("../services/stripeService");
const { sendOrderConfirmation } = require("../services/mailService");

const SHIPPING_EGP = 50; // flat shipping for now

// POST /api/orders — creates order in pending_payment, returns clientSecret
// (or marks as paid immediately if Stripe not configured — mock mode).
router.post("/", authMiddleware, validate(createOrderSchema), async (req, res) => {
    try {
        const { items: reqItems, address, receiptEmail } = req.body;

        // Build snapshot from authoritative DB prices (never trust client prices).
        const ids = reqItems.map((i) => i.product);
        const products = await Product.find({ _id: { $in: ids } }).lean();
        const byId = new Map(products.map((p) => [String(p._id), p]));

        const items = [];
        for (const it of reqItems) {
            const p = byId.get(String(it.product));
            if (!p) {
                return res
                    .status(400)
                    .json({ message: "One of the items is no longer available." });
            }
            if (p.isConcept) {
                return res
                    .status(400)
                    .json({ message: `${p.title?.en || p.slug} is not for sale yet.` });
            }
            if (p.stock < it.qty) {
                return res.status(400).json({
                    message: `${p.title?.en || p.slug} has only ${p.stock} in stock.`,
                });
            }
            items.push({
                product: p._id,
                slug: p.slug,
                titleEn: p.title?.en || p.slug,
                titleAr: p.title?.ar || "",
                image: p.images?.[0]?.src || "",
                unitPriceEGP: p.priceEGP,
                qty: it.qty,
            });
        }

        const subtotalEGP = items.reduce(
            (s, i) => s + i.unitPriceEGP * i.qty,
            0
        );
        const shippingEGP = SHIPPING_EGP;
        const totalEGP = subtotalEGP + shippingEGP;

        const order = await Order.create({
            user: req.user.id,
            items,
            subtotalEGP,
            shippingEGP,
            totalEGP,
            address,
            receiptEmail,
            paymentProvider: stripeSvc.isEnabled() ? "stripe" : "mock",
        });

        // Stripe path
        if (stripeSvc.isEnabled()) {
            const stripe = stripeSvc.getStripe();
            const pi = await stripe.paymentIntents.create({
                amount: Math.round(totalEGP * 100),
                currency: (process.env.STRIPE_CURRENCY || "egp").toLowerCase(),
                receipt_email: receiptEmail,
                metadata: { orderId: String(order._id), userId: String(req.user.id) },
                automatic_payment_methods: { enabled: true },
            });
            order.paymentIntentId = pi.id;
            await order.save();
            return res.status(201).json({
                orderId: order._id,
                clientSecret: pi.client_secret,
                provider: "stripe",
            });
        }

        // Mock path — mark as paid, decrement stock, clear cart, send email
        order.status = "paid";
        order.paidAt = new Date();
        await order.save();

        await Promise.all(
            items.map((i) =>
                Product.updateOne(
                    { _id: i.product, stock: { $gte: i.qty } },
                    { $inc: { stock: -i.qty } }
                )
            )
        );
        await Cart.findOneAndUpdate(
            { user: req.user.id },
            { $set: { items: [] } }
        );
        sendOrderConfirmation(order).catch(() => {});

        return res.status(201).json({
            orderId: order._id,
            clientSecret: null,
            provider: "mock",
        });
    } catch (err) {
        console.error("POST order error:", err);
        res.status(500).json({ message: "Failed to create order" });
    }
});

// GET /api/orders — current user's orders
router.get("/", authMiddleware, async (req, res) => {
    try {
        const orders = await Order.find({ user: req.user.id })
            .sort({ createdAt: -1 })
            .lean();
        res.json({ orders });
    } catch (err) {
        console.error("GET orders error:", err);
        res.status(500).json({ message: "Failed to load orders" });
    }
});

// GET /api/orders/:id — owner only
router.get("/:id", authMiddleware, async (req, res) => {
    try {
        const order = await Order.findOne({
            _id: req.params.id,
            user: req.user.id,
        }).lean();
        if (!order) return res.status(404).json({ message: "Order not found" });
        res.json({ order });
    } catch (err) {
        console.error("GET order error:", err);
        res.status(500).json({ message: "Failed to load order" });
    }
});

module.exports = router;
