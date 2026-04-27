// models/Product.js
const mongoose = require("mongoose");

const BilingualString = {
    en: { type: String, default: "" },
    ar: { type: String, default: "" },
};

const FeatureSchema = new mongoose.Schema(
    {
        icon: { type: String, default: "Sparkles" }, // lucide-react icon name
        title: BilingualString,
        desc: BilingualString,
    },
    { _id: false }
);

const SpecSchema = new mongoose.Schema(
    {
        label: BilingualString,
        value: BilingualString,
    },
    { _id: false }
);

const ImageSchema = new mongoose.Schema(
    {
        src: { type: String, required: true },
        alt: BilingualString,
    },
    { _id: false }
);

const ProductSchema = new mongoose.Schema(
    {
        slug: { type: String, required: true, unique: true, index: true },
        category: {
            type: String,
            enum: ["hardware", "digital", "concept"],
            required: true,
            default: "hardware",
        },
        title: BilingualString,
        tagline: BilingualString,
        description: BilingualString,

        features: { type: [FeatureSchema], default: [] },
        specs: { type: [SpecSchema], default: [] },
        images: { type: [ImageSchema], default: [] },

        priceEGP: { type: Number, required: true, min: 0, default: 0 },
        compareAtEGP: { type: Number, min: 0 },
        stock: { type: Number, default: 0, min: 0 },

        isConcept: { type: Boolean, default: false },
        isFeatured: { type: Boolean, default: false },

        // Denormalised review aggregates (maintained by Review model hooks)
        ratingAvg: { type: Number, default: 0, min: 0, max: 5 },
        ratingCount: { type: Number, default: 0, min: 0 },
    },
    { timestamps: true }
);

const Product =
    mongoose.models.Product || mongoose.model("Product", ProductSchema);

module.exports = Product;
