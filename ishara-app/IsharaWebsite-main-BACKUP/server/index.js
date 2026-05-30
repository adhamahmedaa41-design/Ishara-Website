const path = require("path");
require("dotenv").config({ path: path.join(__dirname, ".env") });
const express = require("express");
const cors = require("cors");
const rateLimit = require("express-rate-limit");
const multer = require("multer");
const fs = require("fs");
const profileRoutes = require("./Routes/usersRoutes");
const chatbotRoutes = require("./Routes/chatbotRoutes");
const connectDB = require("./config/dbConfig");
const authRoutes = require("./Routes/authRoutes");
const contactRoutes = require("./Routes/contactRoutes");
const productRoutes = require("./Routes/productRoutes");
const reviewRoutes = require("./Routes/reviewRoutes");
const cartRoutes = require("./Routes/cartRoutes");
const orderRoutes = require("./Routes/orderRoutes");
const paymentRoutes = require("./Routes/paymentRoutes");
const chatRoutes = require("./Routes/chatRoutes");
const sosRoutes = require("./Routes/sosRoutes");

const app = express();
const PORT = process.env.PORT || 3000;

// Ensure uploads directory exists. On Vercel only /tmp is writable.
const uploadsDir = process.env.VERCEL ? "/tmp/uploads" : "./uploads";
try {
  if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
  }
} catch (err) {
  console.warn("Could not create uploads dir:", err.message);
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 },
});

// Stripe webhook must receive the *raw* body for signature verification,
// so mount it BEFORE express.json(). All other routes use parsed JSON.
app.use(
  "/api/payments/stripe/webhook",
  express.raw({ type: "application/json" })
);

app.use(express.json());

// CORS — single registration, never throws on preflight.
const allowedOrigins = (process.env.CLIENT_ORIGIN || "")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);

app.use(
  cors({
    origin(origin, cb) {
      if (!origin) return cb(null, true);
      if (/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)) {
        return cb(null, true);
      }
      if (/^https:\/\/ishara-website[\w-]*\.vercel\.app$/.test(origin)) {
        return cb(null, true);
      }
      if (allowedOrigins.includes(origin)) return cb(null, true);
      if (allowedOrigins.length === 0) return cb(null, true);
      return cb(null, false);
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

// Make sure preflight is answered before any auth/rate-limit middleware.
// Regex catch-all because Express 5 / path-to-regexp v6+ rejects "*".
app.options(/.*/, cors());

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => req.method === "OPTIONS",
});
app.use(limiter);

// On Vercel (serverless), ensure DB is connected before handling each request.
if (process.env.VERCEL) {
  let dbReady = null;
  app.use(async (req, res, next) => {
    try {
      if (!dbReady) dbReady = connectDB();
      await dbReady;
      next();
    } catch (err) {
      dbReady = null;
      console.error("DB connection error:", err.message);
      res.status(500).json({ message: "Database connection failed" });
    }
  });
}

// Debug middleware loading
console.log("=== DEBUG: Checking authMiddleware ===");
try {
  const auth = require("./middleware/authMiddleware");
  console.log("✅ authMiddleware loaded successfully");
  console.log("Exports:", Object.keys(auth));
} catch (err) {
  console.error("❌ Error loading authMiddleware:", err.message);
}

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/contact", contactRoutes);
app.use("/api/products", productRoutes);
app.use("/api", reviewRoutes);
app.use("/api/cart", cartRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/chat", chatRoutes);
app.use("/api/sos", sosRoutes);

app.post("/api/upload", upload.single("file"), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "No file uploaded" });
    }
    res.json({
      message: "File uploaded successfully",
      filename: req.file.filename,
      originalname: req.file.originalname,
      size: req.file.size,
      mimetype: req.file.mimetype,
      path: `/uploads/${req.file.filename}`,
    });
  } catch (error) {
    console.error("Upload error:", error);
    res
      .status(500)
      .json({ message: "File upload failed", error: error.message });
  }
});

app.use("/public", express.static(path.join(__dirname, "public")));
// Serve uploads from the same directory multer writes to (on Vercel: /tmp/uploads)
app.use("/uploads", express.static(uploadsDir));

app.use("/api/users", profileRoutes);
app.use("/api/chatbot", chatbotRoutes);

app.get("/", (req, res) => {
  res.json({ message: "API Server is running 🟢" });
});

app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && "body" in err) {
    return res.status(400).json({ message: "Invalid JSON" });
  }
  next(err);
});

app.use((err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === "LIMIT_FILE_SIZE") {
      return res
        .status(400)
        .json({ message: "File too large. Max size is 5MB" });
    }
    return res.status(400).json({ message: err.message });
  }
  next(err);
});

if (!process.env.VERCEL) {
  connectDB()
    .then(() => {
      app.listen(PORT, () => {
        console.log(`Server is running on port ${PORT}`);
      });
    })
    .catch((err) => {
      console.error("DB connection error:", err.message);
      process.exit(1);
    });
}

// IMPORTANT: Vercel's api/index.js wrapper does `module.exports = require("../index.js")`,
// so this file MUST export the Express app for serverless to work.
module.exports = app;
