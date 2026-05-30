const express = require("express");
const sanitizeHtml = require("sanitize-html");
const router = express.Router();

const Product = require("../models/Product");
const Review = require("../models/Review");
const User = require("../models/User");
const { authMiddleware } = require("../middleware/authMiddleware");
const { validate } = require("../middleware/validate");
const {
    createReviewSchema,
    updateReviewSchema,
} = require("../validation/reviewSchemas");

const cleanText = (s) =>
    sanitizeHtml(s || "", { allowedTags: [], allowedAttributes: {} }).trim();

// GET /api/products/:slug/reviews — public, paginated
router.get("/products/:slug/reviews", async (req, res) => {
    try {
        const product = await Product.findOne({ slug: req.params.slug })
            .select("_id ratingAvg ratingCount")
            .lean();
        if (!product) return res.status(404).json({ message: "Product not found" });

        const page = Math.max(parseInt(req.query.page) || 1, 1);
        const limit = Math.min(parseInt(req.query.limit) || 10, 50);
        const skip = (page - 1) * limit;

        const [reviews, total] = await Promise.all([
            Review.find({ product: product._id })
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit)
                .lean(),
            Review.countDocuments({ product: product._id }),
        ]);

        res.json({
            reviews,
            total,
            page,
            pageCount: Math.ceil(total / limit),
            summary: {
                ratingAvg: product.ratingAvg,
                ratingCount: product.ratingCount,
            },
        });
    } catch (err) {
        console.error("GET reviews error:", err);
        res.status(500).json({ message: "Failed to load reviews" });
    }
});

// POST /api/products/:slug/reviews — auth
router.post(
    "/products/:slug/reviews",
    authMiddleware,
    validate(createReviewSchema),
    async (req, res) => {
        try {
            const product = await Product.findOne({ slug: req.params.slug }).select("_id");
            if (!product) return res.status(404).json({ message: "Product not found" });

            const user = await User.findById(req.user.id).select("name profilePic");
            if (!user) return res.status(401).json({ message: "User not found" });

            const review = await Review.create({
                user: req.user.id,
                product: product._id,
                userName: user.name,
                userAvatar: user.profilePic || "",
                rating: req.body.rating,
                text: cleanText(req.body.text),
            });
            res.status(201).json({ review });
        } catch (err) {
            if (err && err.code === 11000) {
                return res
                    .status(409)
                    .json({ message: "You have already reviewed this product." });
            }
            console.error("POST review error:", err);
            res.status(500).json({ message: "Failed to submit review" });
        }
    }
);

// PUT /api/reviews/:id — owner only
router.put(
    "/reviews/:id",
    authMiddleware,
    validate(updateReviewSchema),
    async (req, res) => {
        try {
            const update = {};
            if (req.body.rating !== undefined) update.rating = req.body.rating;
            if (req.body.text !== undefined) update.text = cleanText(req.body.text);

            const review = await Review.findOneAndUpdate(
                { _id: req.params.id, user: req.user.id },
                update,
                { new: true }
            );
            if (!review)
                return res.status(404).json({ message: "Review not found" });
            res.json({ review });
        } catch (err) {
            console.error("PUT review error:", err);
            res.status(500).json({ message: "Failed to update review" });
        }
    }
);

// DELETE /api/reviews/:id — owner only
router.delete("/reviews/:id", authMiddleware, async (req, res) => {
    try {
        const review = await Review.findOneAndDelete({
            _id: req.params.id,
            user: req.user.id,
        });
        if (!review) return res.status(404).json({ message: "Review not found" });
        res.json({ message: "Review deleted" });
    } catch (err) {
        console.error("DELETE review error:", err);
        res.status(500).json({ message: "Failed to delete review" });
    }
});

module.exports = router;
