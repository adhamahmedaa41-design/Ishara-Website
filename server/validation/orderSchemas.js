const Joi = require("joi");

const objectId = Joi.string().hex().length(24);

const addressSchema = Joi.object({
    fullName: Joi.string().min(2).max(100).required(),
    phone: Joi.string().min(6).max(30).required(),
    line1: Joi.string().min(3).max(200).required(),
    line2: Joi.string().allow("").max(200),
    city: Joi.string().min(2).max(100).required(),
    governorate: Joi.string().min(2).max(100).required(),
    postalCode: Joi.string().allow("").max(20),
    country: Joi.string().length(2).default("EG"),
});

const createOrderSchema = Joi.object({
    items: Joi.array()
        .items(
            Joi.object({
                product: objectId.required(),
                qty: Joi.number().integer().min(1).max(99).required(),
            })
        )
        .min(1)
        .max(50)
        .required(),
    address: addressSchema.required(),
    receiptEmail: Joi.string().email().required(),
});

module.exports = { createOrderSchema };
