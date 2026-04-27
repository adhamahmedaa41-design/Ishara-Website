const express = require("express");
const router = express.Router();
const Product = require("../models/Product");

// GET /api/products?category=&q=&featured=
router.get("/", async (req, res) => {
    try {
        const { category, q, featured } = req.query;
        const filter = {};
        if (category) filter.category = category;
        if (featured === "true") filter.isFeatured = true;
        if (q) {
            const rx = new RegExp(String(q).trim(), "i");
            filter.$or = [
                { "title.en": rx },
                { "title.ar": rx },
                { "tagline.en": rx },
                { "tagline.ar": rx },
                { slug: rx },
            ];
        }

        const products = await Product.find(filter)
            .sort({ isFeatured: -1, createdAt: -1 })
            .lean();
        res.json({ products });
    } catch (err) {
        console.error("GET /products error:", err);
        res.status(500).json({ message: "Failed to load products" });
    }
});

// GET /api/products/:slug
router.get("/:slug", async (req, res) => {
    try {
        const product = await Product.findOne({ slug: req.params.slug }).lean();
        if (!product) return res.status(404).json({ message: "Product not found" });
        res.json({ product });
    } catch (err) {
        console.error("GET /products/:slug error:", err);
        res.status(500).json({ message: "Failed to load product" });
    }
});

module.exports = router;
