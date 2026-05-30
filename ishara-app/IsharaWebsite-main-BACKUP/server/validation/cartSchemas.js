const Joi = require("joi");

const objectId = Joi.string().hex().length(24);

const cartReplaceSchema = Joi.object({
    items: Joi.array()
        .items(
            Joi.object({
                product: objectId.required(),
                qty: Joi.number().integer().min(1).max(99).required(),
            })
        )
        .max(50)
        .required(),
});

module.exports = { cartReplaceSchema };
