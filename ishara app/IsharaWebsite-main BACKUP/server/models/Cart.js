// models/Cart.js
const mongoose = require("mongoose");

const CartItemSchema = new mongoose.Schema(
    {
        product: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Product",
            required: true,
        },
        qty: { type: Number, required: true, min: 1, max: 99, default: 1 },
    },
    { _id: false }
);

const CartSchema = new mongoose.Schema(
    {
        user: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            unique: true,
            index: true,
        },
        items: { type: [CartItemSchema], default: [] },
    },
    { timestamps: true }
);

const Cart = mongoose.models.Cart || mongoose.model("Cart", CartSchema);
module.exports = Cart;
