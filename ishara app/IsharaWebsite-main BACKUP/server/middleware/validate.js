// middleware/validate.js
// Generic Joi validator factory. Mirrors the error shape used by authRoutes
// so the frontend error normalizer handles both identically.
function validate(schema, source = "body") {
    return (req, res, next) => {
        const { error, value } = schema.validate(req[source], {
            abortEarly: false,
            stripUnknown: true,
        });
        if (error) {
            const fieldErrors = (error.details || []).map((d) => ({
                field:
                    Array.isArray(d.path) && d.path.length
                        ? String(d.path[0])
                        : "unknown",
                message: d.message,
            }));
            return res.status(400).json({
                message: "Please check the highlighted fields and try again.",
                errors: fieldErrors,
            });
        }
        req[source] = value;
        next();
    };
}

module.exports = { validate };
