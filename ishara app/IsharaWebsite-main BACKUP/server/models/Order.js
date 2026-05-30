// models/Order.js
const mongoose = require("mongoose");

// Snapshot of the product at purchase time — price and title must NOT
// change if the underlying product is later edited.
const OrderItemSchema = new mongoose.Schema(
    {
        product: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Product",
            required: true,
        },
        slug: { type: String, required: true },
        titleEn: { type: String, required: true },
        titleAr: { type: String, default: "" },
        image: { type: String, default: "" },
        unitPriceEGP: { type: Number, required: true, min: 0 },
        qty: { type: Number, required: true, min: 1 },
    },
    { _id: false }
);

const AddressSchema = new mongoose.Schema(
    {
        fullName: { type: String, required: true },
        phone: { type: String, required: true },
        line1: { type: String, required: true },
        line2: { type: String, default: "" },
        city: { type: String, required: true },
        governorate: { type: String, required: true },
        postalCode: { type: String, default: "" },
        country: { type: String, default: "EG" },
    },
    { _id: false }
);

const OrderSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true,
        },
        items: { type: [OrderItemSchema], required: true },
        subtotalEGP: { type: Number, required: true, min: 0 },
        shippingEGP: { type: Number, default: 0, min: 0 },
        totalEGP: { type: Number, required: true, min: 0 },
        currency: { type: String, default: "EGP" },

        address: { type: AddressSchema, required: true },
        receiptEmail: { type: String, required: true },

        status: {
            type: String,
            enum: [
                "pending_payment",
                "paid",
                "fulfilled",
                "cancelled",
                "refunded",
            ],
            default: "pending_payment",
            index: true,
        },
        paymentProvider: {
            type: String,
            enum: ["stripe", "mock"],
            default: "stripe",
        },
        paymentIntentId: { type: String, default: "" },
        paidAt: { type: Date },
    },
    { timestamps: true }
);

const Order = mongoose.models.Order || mongoose.model("Order", OrderSchema);
module.exports = Order;
