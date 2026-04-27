// models/Review.js
const mongoose = require("mongoose");
const Product = require("./Product");

const ReviewSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true,
        },
        product: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Product",
            required: true,
            index: true,
        },
        // Denormalised for quick list rendering without populate()
        userName: { type: String, required: true },
        userAvatar: { type: String, default: "" },

        rating: { type: Number, required: true, min: 1, max: 5 },
        text: { type: String, default: "", maxlength: 2000 },
    },
    { timestamps: true }
);

// Enforce "one review per user per product" at the DB layer.
ReviewSchema.index({ user: 1, product: 1 }, { unique: true });

// Recompute product aggregates whenever reviews change.
async function recomputeAggregates(productId) {
    const Review = mongoose.model("Review");
    const agg = await Review.aggregate([
        { $match: { product: new mongoose.Types.ObjectId(productId) } },
        {
            $group: {
                _id: "$product",
                avg: { $avg: "$rating" },
                count: { $sum: 1 },
            },
        },
    ]);
    const { avg = 0, count = 0 } = agg[0] || {};
    await Product.updateOne(
        { _id: productId },
        {
            $set: {
                ratingAvg: Math.round((avg + Number.EPSILON) * 10) / 10,
                ratingCount: count,
            },
        }
    );
}

ReviewSchema.post("save", async function (doc) {
    try {
        await recomputeAggregates(doc.product);
    } catch (err) {
        console.error("Review aggregate recompute failed:", err.message);
    }
});

ReviewSchema.post("findOneAndUpdate", async function (doc) {
    if (doc) await recomputeAggregates(doc.product);
});

ReviewSchema.post("findOneAndDelete", async function (doc) {
    if (doc) await recomputeAggregates(doc.product);
});

const Review =
    mongoose.models.Review || mongoose.model("Review", ReviewSchema);

module.exports = Review;
