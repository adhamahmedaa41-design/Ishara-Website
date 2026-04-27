const Joi = require("joi");

const createReviewSchema = Joi.object({
    rating: Joi.number().integer().min(1).max(5).required(),
    text: Joi.string().allow("").max(2000).default(""),
});

const updateReviewSchema = Joi.object({
    rating: Joi.number().integer().min(1).max(5),
    text: Joi.string().allow("").max(2000),
}).min(1);

module.exports = { createReviewSchema, updateReviewSchema };
