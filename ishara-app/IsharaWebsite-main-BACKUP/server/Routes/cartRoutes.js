const express = require("express");
const router = express.Router();

const Cart = require("../models/Cart");
const Product = require("../models/Product");
const { authMiddleware } = require("../middleware/authMiddleware");
const { validate } = require("../middleware/validate");
const { cartReplaceSchema } = require("../validation/cartSchemas");

// Hydrate cart with product snapshots for the client.
async function hydrate(cart) {
    if (!cart || !cart.items.length) {
        return { items: [], subtotalEGP: 0 };
    }
    const ids = cart.items.map((i) => i.product);
    const products = await Product.find({ _id: { $in: ids } })
        .select("slug title images priceEGP stock isConcept")
        .lean();
    const byId = new Map(products.map((p) => [String(p._id), p]));

    const items = cart.items
        .map((i) => {
            const p = byId.get(String(i.product));
            if (!p || p.isConcept) return null; // drop unavailable / concept items
            return {
                product: p._id,
                slug: p.slug,
                title: p.title,
                image: p.images?.[0]?.src || "",
                priceEGP: p.priceEGP,
                stock: p.stock,
                qty: Math.min(i.qty, 99),
            };
        })
        .filter(Boolean);

    const subtotalEGP = items.reduce((s, i) => s + i.priceEGP * i.qty, 0);
    return { items, subtotalEGP };
}

// GET /api/cart
router.get("/", authMiddleware, async (req, res) => {
    try {
        const cart = await Cart.findOne({ user: req.user.id });
        res.json(await hydrate(cart));
    } catch (err) {
        console.error("GET cart error:", err);
        res.status(500).json({ message: "Failed to load cart" });
    }
});

// PUT /api/cart — full replace
router.put("/", authMiddleware, validate(cartReplaceSchema), async (req, res) => {
    try {
        // Dedupe by product (sum qty, clamp to 99)
        const merged = new Map();
        for (const it of req.body.items) {
            const key = String(it.product);
            merged.set(key, Math.min((merged.get(key) || 0) + it.qty, 99));
        }
        const items = [...merged.entries()].map(([product, qty]) => ({
            product,
            qty,
        }));

        const cart = await Cart.findOneAndUpdate(
            { user: req.user.id },
            { $set: { items } },
            { upsert: true, new: true }
        );
        res.json(await hydrate(cart));
    } catch (err) {
        console.error("PUT cart error:", err);
        res.status(500).json({ message: "Failed to update cart" });
    }
});

// DELETE /api/cart
router.delete("/", authMiddleware, async (req, res) => {
    try {
        await Cart.findOneAndUpdate(
            { user: req.user.id },
            { $set: { items: [] } },
            { upsert: true }
        );
        res.json({ items: [], subtotalEGP: 0 });
    } catch (err) {
        console.error("DELETE cart error:", err);
        res.status(500).json({ message: "Failed to clear cart" });
    }
});

module.exports = router;
