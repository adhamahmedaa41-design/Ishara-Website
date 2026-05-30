const Joi = require("joi");

const chatSchema = Joi.object({
    lang: Joi.string().valid("en", "ar").default("en"),
    messages: Joi.array()
        .items(
            Joi.object({
                role: Joi.string().valid("user", "assistant").required(),
                content: Joi.string().min(1).max(4000).required(),
            })
        )
        .min(1)
        .max(30)
        .required(),
});

module.exports = { chatSchema };
