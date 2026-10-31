const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const express = require("express");
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const cors = require("cors");
const nodemailer = require("nodemailer");

// Load developer-only server credentials without exposing them to Flutter or
// the generated web bundle. Deployment environments can continue to provide
// these values directly and always take precedence over this local file.
const localEnvPath = path.join(__dirname, ".env.local");
if (fs.existsSync(localEnvPath)) {
  for (const rawLine of fs.readFileSync(localEnvPath, "utf8").split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;
    const separator = line.indexOf("=");
    if (separator <= 0) continue;
    const name = line.slice(0, separator).trim();
    const value = line.slice(separator + 1).trim();
    if (!process.env[name]) process.env[name] = value;
  }
}

const PORT = Number(process.env.PORT || 4000);
const MONGODB_URI =
  process.env.MONGODB_URI || "mongodb://127.0.0.1:27017/divinewall";
const SESSION_DAYS = Number(process.env.SESSION_DAYS || 30);
const ADMIN_EMAIL = String(process.env.ADMIN_EMAIL || "admin@gmail.com").trim().toLowerCase();
const ADMIN_PASSWORD = String(process.env.ADMIN_PASSWORD || "");
const ADMIN_SESSION_HOURS = Number(process.env.ADMIN_SESSION_HOURS || 12);
const RAZORPAY_KEY_ID = String(process.env.RAZORPAY_KEY_ID || "").trim();
const RAZORPAY_KEY_SECRET = String(process.env.RAZORPAY_KEY_SECRET || "").trim();
const PURCHASE_MAIL_TO = String(
  process.env.PURCHASE_MAIL_TO || "Kubervastu153@gmail.com",
).trim();
const GMAIL_USER = String(process.env.GMAIL_USER || "").trim();
const GMAIL_APP_PASSWORD = String(process.env.GMAIL_APP_PASSWORD || "").replace(/\s/g, "");
const adminSessions = new Map();
const premiumRemedies = require("./data/remedies-catalog.json");

const defaultRemedies = [
  {
    id: "wealth-kalash",
    title: "Wealth Kalash",
    subtitle: "North prosperity balancing kit",
    direction: "North",
    purpose: "Prosperity and steady opportunities",
    category: "Wealth & Prosperity",
    price: 799,
  },
  {
    id: "agni-copper",
    title: "Agni Copper Set",
    subtitle: "Southeast fire element support",
    direction: "Southeast",
    purpose: "Energy, kitchen harmony, and transformation",
    category: "Health & Energy",
    price: 1199,
  },
  {
    id: "ishanya-crystal",
    title: "Ishanya Crystal",
    subtitle: "Northeast clarity and prayer corner remedy",
    direction: "Northeast",
    purpose: "Clarity, devotion, and peaceful study",
    category: "Clarity & Spiritual Growth",
    price: 999,
  },
  {
    id: "vayu-bells",
    title: "Vayu Bells",
    subtitle: "Northwest movement and relationship remedy",
    direction: "Northwest",
    purpose: "Supportive relationships and better flow",
    category: "Relationships & Harmony",
    price: 699,
  },
];
defaultRemedies.push(...premiumRemedies);

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    gender: { type: String, default: "", trim: true },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    phone: { type: String, default: "", trim: true },
    place: { type: String, default: "", trim: true },
    userType: { type: String, default: "", trim: true },
    username: {
      type: String,
      lowercase: true,
      trim: true,
      unique: true,
      sparse: true,
      index: true,
    },
    passwordHash: { type: String, required: true },
    lastLoginAt: Date,
    lastLogoutAt: Date,
  },
  { timestamps: true },
);

const sessionSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", index: true },
    tokenHash: { type: String, required: true, unique: true, index: true },
    expiresAt: { type: Date, required: true, index: true },
    revokedAt: Date,
  },
  { timestamps: true },
);
sessionSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

const remedySchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, trim: true },
    title: { type: String, required: true, trim: true },
    subtitle: { type: String, default: "", trim: true },
    direction: { type: String, required: true, trim: true },
    purpose: { type: String, required: true, trim: true },
    category: { type: String, default: "General Remedies", trim: true },
    price: { type: Number, default: 0 },
    whyYouNeed: { type: String, default: "", trim: true },
    howItWorks: { type: String, default: "", trim: true },
    whatYouGet: { type: String, default: "", trim: true },
    placement: { type: String, default: "", trim: true },
    offers: { type: [String], default: [] },
    imageUrls: { type: [String], default: [] },
    videoUrls: { type: [String], default: [] },
    installationImageUrls: { type: [String], default: [] },
    installationVideoUrls: { type: [String], default: [] },
  },
  { timestamps: true },
);

const orderSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", index: true },
    remedyId: { type: String, required: true },
    remedyName: { type: String, required: true },
    quantity: { type: Number, min: 1, default: 1 },
    unitPrice: { type: Number, default: 0 },
    price: { type: Number, default: 0 },
    status: { type: String, default: "created" },
    purchasedAt: { type: Date, default: Date.now },
    validityStartsAt: Date,
    validityEndsAt: Date,
    paymentId: { type: String, default: "", trim: true },
    shipping: { name: String, phone: String, address: String, city: String, state: String, pincode: String },
  },
  { timestamps: true },
);

const purchaseSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", index: true },
    items: [{ remedyId: String, remedyName: String, quantity: Number, unitPrice: Number }],
    total: { type: Number, required: true },
    currency: { type: String, default: "INR" },
    status: {
      type: String,
      enum: ["pending", "paid", "failed"],
      default: "pending",
      index: true,
    },
    checkoutTokenHash: { type: String, required: true, unique: true, index: true },
    razorpayOrderId: { type: String, required: true, unique: true, index: true },
    razorpayPaymentId: { type: String, default: "", trim: true },
    shipping: { name: String, phone: String, address: String, city: String, state: String, pincode: String },
    paidAt: Date,
    validityEndsAt: Date,
  },
  { timestamps: true },
);

const appUpdateSchema = new mongoose.Schema(
  {
    key: { type: String, required: true, unique: true, default: "mobile-app" },
    enabled: { type: Boolean, default: true },
    latestVersion: { type: String, default: process.env.APP_LATEST_VERSION || "1.0.0" },
    latestBuildNumber: { type: Number, default: Number(process.env.APP_LATEST_BUILD || 1) },
    downloadUrl: { type: String, default: process.env.APP_DOWNLOAD_URL || "" },
    releaseNotes: {
      type: String,
      default: process.env.APP_UPDATE_MESSAGE || "A new Kubar Vastu app update is available.",
    },
    forceUpdate: {
      type: Boolean,
      default: String(process.env.APP_FORCE_UPDATE || "").toLowerCase() === "true",
    },
  },
  { timestamps: true },
);

const blogSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    description: { type: String, required: true, trim: true },
    content: { type: String, required: true, trim: true },
    imageUrl: { type: String, default: "", trim: true },
    category: { type: String, default: "Vastu", trim: true, index: true },
    published: { type: Boolean, default: true, index: true },
    publishedAt: { type: Date, default: Date.now, index: true },
  },
  { timestamps: true },
);

const testimonialSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    profileImageUrl: { type: String, default: "", trim: true },
    rating: { type: Number, min: 1, max: 5, default: 5 },
    review: { type: String, required: true, trim: true },
    status: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
      index: true,
    },
  },
  { timestamps: true },
);

const videoSchema = new mongoose.Schema(
  {
    videoId: { type: String, required: true, unique: true, trim: true },
    title: { type: String, required: true, trim: true },
    thumbnailUrl: { type: String, default: "", trim: true },
    published: { type: Boolean, default: true, index: true },
    publishedAt: { type: Date, default: Date.now, index: true },
  },
  { timestamps: true },
);

const User = mongoose.model("User", userSchema);
const Session = mongoose.model("Session", sessionSchema);
const Remedy = mongoose.model("Remedy", remedySchema);
const Order = mongoose.model("Order", orderSchema);
const Purchase = mongoose.model("Purchase", purchaseSchema);
const AppUpdate = mongoose.model("AppUpdate", appUpdateSchema);
const Blog = mongoose.model("Blog", blogSchema);
const Testimonial = mongoose.model("Testimonial", testimonialSchema);
const ContentVideo = mongoose.model("ContentVideo", videoSchema);

function normalizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function normalizeUsername(username) {
  return String(username || "").trim().toLowerCase();
}

function validEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function validPhone(phone) {
  return /^\+?[0-9]{10,15}$/.test(String(phone || "").replace(/[\s-]/g, ""));
}

let purchaseMailer;

function getPurchaseMailer() {
  if (!GMAIL_USER || !GMAIL_APP_PASSWORD) return null;
  purchaseMailer ??= nodemailer.createTransport({
    service: "gmail",
    auth: { user: GMAIL_USER, pass: GMAIL_APP_PASSWORD },
  });
  return purchaseMailer;
}

async function sendPurchaseNotification({ customer, items, total, paymentId, status, shipping }) {
  const mailer = getPurchaseMailer();
  if (!mailer) {
    console.warn(
      "Purchase email skipped: configure GMAIL_USER and GMAIL_APP_PASSWORD.",
    );
    return false;
  }

  const safeItems = Array.isArray(items) ? items : [];
  const itemLines = safeItems.map((item, index) => {
    const quantity = Number(item.quantity || 1);
    const unitPrice = Number(item.unitPrice || item.price || 0);
    return `${index + 1}. ${item.remedyName || "Service / Remedy"} x ${quantity} - INR ${unitPrice * quantity}`;
  });
  const lines = [
    "A new Kuber Vastu purchase has been received.",
    "",
    `Customer: ${customer?.name || "Unknown"}`,
    `Email: ${customer?.email || "Not provided"}`,
    `Phone: ${customer?.phone || "Not provided"}`,
    `Place: ${customer?.place || "Not provided"}`,
    ...(shipping ? [
      `Ship to: ${shipping.name}`,
      `Shipping phone: ${shipping.phone}`,
      `Shipping address: ${shipping.address}, ${shipping.city}, ${shipping.state} - ${shipping.pincode}`,
    ] : []),
    `Status: ${status || "created"}`,
    `Payment ID: ${paymentId || "Not available"}`,
    "",
    "Items:",
    ...(itemLines.length ? itemLines : ["No item details available"]),
    "",
    `Total: INR ${Number(total || 0)}`,
    `Time: ${new Date().toLocaleString("en-IN", { timeZone: "Asia/Kolkata" })}`,
  ];

  try {
    await mailer.sendMail({
      from: `Kuber Vastu Orders <${GMAIL_USER}>`,
      to: PURCHASE_MAIL_TO,
      subject: `New Kuber Vastu purchase - INR ${Number(total || 0)}`,
      text: lines.join("\n"),
    });
    return true;
  } catch (error) {
    console.error("Purchase email failed:", error.message);
    return false;
  }
}

function requireFields(body, fields) {
  const missing = fields.filter((field) => !String(body[field] || "").trim());
  return missing.length ? `Missing required field(s): ${missing.join(", ")}` : null;
}

function publicUser(user) {
  return {
    id: String(user._id),
    name: user.name,
    gender: user.gender || "",
    email: user.email,
    phone: user.phone || "",
    place: user.place || "",
    userType: user.userType || "",
    username: user.username || "",
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
    lastLoginAt: user.lastLoginAt,
    lastLogoutAt: user.lastLogoutAt,
  };
}

function publicRemedy(remedy) {
  return {
    id: remedy.id,
    title: remedy.title,
    subtitle: remedy.subtitle || "",
    direction: remedy.direction,
    purpose: remedy.purpose,
    category: remedy.category || "General Remedies",
    price: remedy.price,
    whyYouNeed: remedy.whyYouNeed || "",
    howItWorks: remedy.howItWorks || "",
    whatYouGet: remedy.whatYouGet || "",
    placement: remedy.placement || "",
    offers: Array.isArray(remedy.offers) ? remedy.offers.slice(0, 8) : [],
    imageUrls: Array.isArray(remedy.imageUrls) ? remedy.imageUrls.slice(0, 10) : [],
    videoUrls: Array.isArray(remedy.videoUrls) ? remedy.videoUrls.slice(0, 6) : [],
    installationImageUrls: Array.isArray(remedy.installationImageUrls) ? remedy.installationImageUrls.slice(0, 10) : [],
    installationVideoUrls: Array.isArray(remedy.installationVideoUrls) ? remedy.installationVideoUrls.slice(0, 6) : [],
    createdAt: remedy.createdAt,
    updatedAt: remedy.updatedAt,
  };
}

function publicOrder(order) {
  return {
    id: String(order._id),
    userId: String(order.userId),
    remedyId: order.remedyId,
    remedyName: order.remedyName,
    quantity: Number(order.quantity || 1),
    unitPrice: Number(order.unitPrice || order.price || 0),
    price: order.price,
    status: order.status,
    purchasedAt: order.purchasedAt,
    validityStartsAt: order.validityStartsAt || order.purchasedAt,
    validityEndsAt: order.validityEndsAt || null,
    paymentId: order.paymentId || "",
    shipping: order.shipping || null,
  };
}

function publicAppUpdate(update) {
  return {
    enabled: Boolean(update.enabled),
    latestVersion: update.latestVersion || "1.0.0",
    latestBuildNumber: Number(update.latestBuildNumber || 1),
    downloadUrl: update.downloadUrl || "",
    releaseNotes: update.releaseNotes || "",
    forceUpdate: Boolean(update.forceUpdate),
    updatedAt: update.updatedAt,
  };
}

function publicBlog(blog) {
  return {
    id: String(blog._id),
    title: blog.title,
    description: blog.description,
    content: blog.content,
    imageUrl: blog.imageUrl || "",
    category: blog.category || "Vastu",
    published: blog.published !== false,
    publishedAt: blog.publishedAt || blog.createdAt,
  };
}

function publicTestimonial(item) {
  return {
    id: String(item._id),
    name: item.name,
    profileImageUrl: item.profileImageUrl || "",
    rating: item.rating,
    review: item.review,
    status: item.status || "pending",
    createdAt: item.createdAt,
  };
}

function publicVideo(video) {
  return {
    id: video.videoId,
    recordId: String(video._id),
    title: video.title,
    thumbnailUrl:
      video.thumbnailUrl || `https://img.youtube.com/vi/${video.videoId}/hqdefault.jpg`,
    published: video.published !== false,
    publishedAt: video.publishedAt || video.createdAt,
  };
}

function youtubeVideoId(value) {
  const input = String(value || "").trim();
  if (/^[A-Za-z0-9_-]{11}$/.test(input)) return input;
  try {
    const url = new URL(input);
    const candidate = url.hostname.includes("youtu.be")
      ? url.pathname.split("/").filter(Boolean)[0]
      : url.searchParams.get("v") || url.pathname.split("/").filter(Boolean).pop();
    return /^[A-Za-z0-9_-]{11}$/.test(candidate || "") ? candidate : "";
  } catch (_) {
    return "";
  }
}

function hashToken(token) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

function cookieValue(req, name) {
  const cookies = String(req.headers.cookie || "").split(";");
  for (const cookie of cookies) {
    const [key, ...value] = cookie.trim().split("=");
    if (key === name) return decodeURIComponent(value.join("="));
  }
  return "";
}

function requireAdmin(req, res, next) {
  const token = cookieValue(req, "kubar_admin_session");
  const expiresAt = adminSessions.get(hashToken(token));
  if (!token || !expiresAt || expiresAt <= Date.now()) {
    if (token) adminSessions.delete(hashToken(token));
    return res.status(401).json({ error: "Admin login required" });
  }
  next();
}

async function issueSession(user) {
  const token = crypto.randomBytes(32).toString("hex");
  const expiresAt = new Date(Date.now() + SESSION_DAYS * 24 * 60 * 60 * 1000);
  await Session.create({
    userId: user._id,
    tokenHash: hashToken(token),
    expiresAt,
  });
  return { token, expiresAt };
}

async function authenticate(req, res, next) {
  const header = req.get("authorization") || "";
  const [, token] = header.match(/^Bearer\s+(.+)$/i) || [];
  if (!token) return res.status(401).json({ error: "Login required" });

  const session = await Session.findOne({
    tokenHash: hashToken(token),
    revokedAt: null,
    expiresAt: { $gt: new Date() },
  });
  if (!session) return res.status(401).json({ error: "Session expired" });

  const user = await User.findById(session.userId);
  if (!user) return res.status(401).json({ error: "User not found" });

  req.session = session;
  req.user = user;
  next();
}

async function userFromBearer(req) {
  const header = req.get("authorization") || "";
  const [, token] = header.match(/^Bearer\s+(.+)$/i) || [];
  if (!token) return null;

  const session = await Session.findOne({
    tokenHash: hashToken(token),
    revokedAt: null,
    expiresAt: { $gt: new Date() },
  });
  if (!session) return null;
  return User.findById(session.userId);
}

function asyncRoute(handler) {
  return (req, res, next) => Promise.resolve(handler(req, res, next)).catch(next);
}

function cleanRemedy(body, existingId) {
  const title = String(body.title || "").trim();
  const id =
    existingId ||
    String(body.id || title.toLowerCase().replace(/[^a-z0-9]+/g, "-"))
      .replace(/^-+|-+$/g, "")
      .slice(0, 60);

  const cleanList = (values, limit = 6) => (Array.isArray(values) ? values : [])
    .map((value) => String(value || "").trim())
    .filter(Boolean)
    .slice(0, limit);
  return {
    id: id || crypto.randomUUID(),
    title,
    subtitle: String(body.subtitle || "").trim(),
    direction: String(body.direction || "").trim(),
    purpose: String(body.purpose || "").trim(),
    category: String(body.category || "General Remedies").trim(),
    price: Number(body.price || 0),
    whyYouNeed: String(body.whyYouNeed || "").trim(),
    howItWorks: String(body.howItWorks || "").trim(),
    whatYouGet: String(body.whatYouGet || "").trim(),
    placement: String(body.placement || "").trim(),
    offers: cleanList(body.offers, 8),
    imageUrls: cleanList(body.imageUrls, 10),
    videoUrls: cleanList(body.videoUrls, 6),
    installationImageUrls: cleanList(body.installationImageUrls, 10),
    installationVideoUrls: cleanList(body.installationVideoUrls, 6),
  };
}

async function seedRemedies() {
  await Promise.all(
    defaultRemedies.map((remedy) =>
      Remedy.updateOne(
        { id: remedy.id },
        { $setOnInsert: remedy },
        { upsert: true },
      ),
    ),
  );
}

async function getAppUpdateSettings() {
  const defaults = {
    key: "mobile-app",
    enabled: true,
    latestVersion: process.env.APP_LATEST_VERSION || "1.0.0",
    latestBuildNumber: Number(process.env.APP_LATEST_BUILD || 1),
    downloadUrl: process.env.APP_DOWNLOAD_URL || "",
    releaseNotes:
      process.env.APP_UPDATE_MESSAGE || "A new Kubar Vastu app update is available.",
    forceUpdate: String(process.env.APP_FORCE_UPDATE || "").toLowerCase() === "true",
  };
  return AppUpdate.findOneAndUpdate(
    { key: "mobile-app" },
    { $setOnInsert: defaults },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
}

const app = express();
app.use(cors());
app.use(express.json({ limit: "12mb" }));
const uploadsDirectory = path.join(__dirname, "uploads");
fs.mkdirSync(uploadsDirectory, { recursive: true });
app.use("/uploads", express.static(uploadsDirectory));
app.use("/admin", express.static(path.join(__dirname, "admin")));

app.get(["/admin", "/admin/"], (req, res) => {
  res.sendFile(path.join(__dirname, "admin", "index.html"));
});

app.get("/health", (req, res) => {
  res.json({
    ok: true,
    service: "divinewall-backend",
    database: "mongodb",
    razorpayConfigured: Boolean(RAZORPAY_KEY_ID && RAZORPAY_KEY_SECRET),
  });
});

app.post("/api/admin/login", (req, res) => {
  const email = String(req.body.email || "").trim().toLowerCase();
  const password = String(req.body.password || "");
  const emailMatches = email.length === ADMIN_EMAIL.length &&
    crypto.timingSafeEqual(Buffer.from(email), Buffer.from(ADMIN_EMAIL));
  const passwordMatches = password.length === ADMIN_PASSWORD.length &&
    crypto.timingSafeEqual(Buffer.from(password), Buffer.from(ADMIN_PASSWORD));
  if (!ADMIN_PASSWORD || !emailMatches || !passwordMatches) {
    return res.status(401).json({ error: "Invalid admin email or password" });
  }
  const token = crypto.randomBytes(32).toString("hex");
  const maxAgeSeconds = Math.max(1, ADMIN_SESSION_HOURS) * 60 * 60;
  adminSessions.set(hashToken(token), Date.now() + maxAgeSeconds * 1000);
  res.setHeader(
    "Set-Cookie",
    `kubar_admin_session=${encodeURIComponent(token)}; HttpOnly; SameSite=Lax; Path=/; Max-Age=${maxAgeSeconds}`,
  );
  res.json({ ok: true, email: ADMIN_EMAIL });
});

app.get("/api/admin/session", requireAdmin, (req, res) => {
  res.json({ authenticated: true, email: ADMIN_EMAIL });
});

app.post("/api/admin/logout", requireAdmin, (req, res) => {
  const token = cookieValue(req, "kubar_admin_session");
  if (token) adminSessions.delete(hashToken(token));
  res.setHeader(
    "Set-Cookie",
    "kubar_admin_session=; HttpOnly; SameSite=Lax; Path=/; Max-Age=0",
  );
  res.json({ ok: true });
});

app.use("/api/admin", requireAdmin);

app.post("/api/admin/uploads", asyncRoute(async (req, res) => {
  const data = String(req.body.data || "");
  const match = data.match(/^data:(image\/(?:png|jpeg|webp)|video\/(?:mp4|webm));base64,([A-Za-z0-9+/=]+)$/);
  if (!match) return res.status(400).json({ error: "Unsupported image or video file" });
  const bytes = Buffer.from(match[2], "base64");
  if (bytes.length > 8 * 1024 * 1024) return res.status(413).json({ error: "File must be 8 MB or smaller" });
  const extensions = { "image/png": "png", "image/jpeg": "jpg", "image/webp": "webp", "video/mp4": "mp4", "video/webm": "webm" };
  const filename = `${Date.now()}-${crypto.randomUUID()}.${extensions[match[1]]}`;
  await fs.promises.writeFile(path.join(uploadsDirectory, filename), bytes);
  res.status(201).json({ url: `${req.protocol}://${req.get("host")}/uploads/${filename}` });
}));

app.get(
  "/api/content/videos",
  asyncRoute(async (req, res) => {
    const managedVideos = await ContentVideo.find({ published: true })
      .sort({ publishedAt: -1 })
      .limit(20);
    if (managedVideos.length) {
      return res.json({ videos: managedVideos.map(publicVideo) });
    }
    const apiKey = String(process.env.YOUTUBE_API_KEY || "").trim();
    const channelId = String(process.env.YOUTUBE_CHANNEL_ID || "").trim();
    if (!apiKey || !channelId) {
      const configuredIds = String(
        process.env.YOUTUBE_VIDEO_IDS || "ccJZyHd_6EA,dEpKvAtxqEU",
      )
        .split(",")
        .map((id) => id.trim())
        .filter(Boolean)
        .slice(0, 12);
      return res.json({
        videos: configuredIds.map((id, index) => ({
          id,
          title: index === 0 ? "Kubar Vastu Video" : "Featured Vastu Video",
          publishedAt: null,
          thumbnailUrl: `https://img.youtube.com/vi/${id}/hqdefault.jpg`,
        })),
      });
    }
    const url = new URL("https://www.googleapis.com/youtube/v3/search");
    url.search = new URLSearchParams({
      part: "snippet",
      channelId,
      order: "date",
      type: "video",
      maxResults: "12",
      key: apiKey,
    }).toString();
    const response = await fetch(url, {
      headers: { Accept: "application/json" },
      signal: AbortSignal.timeout(8000),
    });
    if (!response.ok) {
      return res.status(502).json({ error: "YouTube service is unavailable" });
    }
    const payload = await response.json();
    const videos = (payload.items || []).map((item) => ({
      id: item.id?.videoId || "",
      title: item.snippet?.title || "Kubar Vastu video",
      publishedAt: item.snippet?.publishedAt || null,
      thumbnailUrl:
        item.snippet?.thumbnails?.high?.url ||
        item.snippet?.thumbnails?.medium?.url ||
        item.snippet?.thumbnails?.default?.url ||
        "",
    })).filter((video) => video.id);
    res.set("Cache-Control", "public, max-age=300, stale-while-revalidate=1800");
    res.json({ videos });
  }),
);

app.post(
  "/api/admin/videos",
  asyncRoute(async (req, res) => {
    const videoId = youtubeVideoId(req.body.youtubeUrl || req.body.videoId);
    const title = String(req.body.title || "").trim();
    if (!videoId) return res.status(400).json({ error: "Valid YouTube URL is required" });
    if (!title) return res.status(400).json({ error: "Video title is required" });
    const video = await ContentVideo.create({
      videoId,
      title,
      thumbnailUrl: String(req.body.thumbnailUrl || "").trim(),
      published: req.body.published !== false,
      publishedAt: new Date(),
    });
    res.status(201).json({ video: publicVideo(video) });
  }),
);

app.put(
  "/api/admin/videos/:id",
  asyncRoute(async (req, res) => {
    const videoId = youtubeVideoId(req.body.youtubeUrl || req.body.videoId);
    const title = String(req.body.title || "").trim();
    if (!videoId) return res.status(400).json({ error: "Valid YouTube URL is required" });
    if (!title) return res.status(400).json({ error: "Video title is required" });
    const video = await ContentVideo.findByIdAndUpdate(
      req.params.id,
      {
        videoId,
        title,
        thumbnailUrl: String(req.body.thumbnailUrl || "").trim(),
        published: req.body.published !== false,
      },
      { new: true, runValidators: true },
    );
    if (!video) return res.status(404).json({ error: "Video not found" });
    res.json({ video: publicVideo(video) });
  }),
);

app.delete(
  "/api/admin/videos/:id",
  asyncRoute(async (req, res) => {
    const video = await ContentVideo.findByIdAndDelete(req.params.id);
    if (!video) return res.status(404).json({ error: "Video not found" });
    res.json({ ok: true });
  }),
);

app.get(
  "/api/blogs",
  asyncRoute(async (req, res) => {
    const page = Math.max(1, Number(req.query.page || 1));
    const limit = Math.min(20, Math.max(1, Number(req.query.limit || 8)));
    const query = String(req.query.q || "").trim();
    const filter = {
      published: true,
      ...(query
        ? {
            $or: ["title", "description", "content", "category"].map(
              (field) => ({ [field]: { $regex: query, $options: "i" } }),
            ),
          }
        : {}),
    };
    const [items, total] = await Promise.all([
      Blog.find(filter)
        .sort({ publishedAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit),
      Blog.countDocuments(filter),
    ]);
    res.json({
      blogs: items.map(publicBlog),
      page,
      hasMore: page * limit < total,
      total,
    });
  }),
);

app.post(
  "/api/admin/blogs",
  asyncRoute(async (req, res) => {
    const error = requireFields(req.body, ["title", "description", "content"]);
    if (error) return res.status(400).json({ error });
    const blog = await Blog.create({
      title: String(req.body.title).trim(),
      description: String(req.body.description).trim(),
      content: String(req.body.content).trim(),
      imageUrl: String(req.body.imageUrl || "").trim(),
      category: String(req.body.category || "Vastu").trim(),
      published: req.body.published !== false,
      publishedAt: req.body.publishedAt || new Date(),
    });
    res.status(201).json({ blog: publicBlog(blog) });
  }),
);

app.put(
  "/api/admin/blogs/:id",
  asyncRoute(async (req, res) => {
    const error = requireFields(req.body, ["title", "description", "content"]);
    if (error) return res.status(400).json({ error });
    const blog = await Blog.findByIdAndUpdate(
      req.params.id,
      {
        title: String(req.body.title).trim(),
        description: String(req.body.description).trim(),
        content: String(req.body.content).trim(),
        imageUrl: String(req.body.imageUrl || "").trim(),
        category: String(req.body.category || "Vastu").trim(),
        published: req.body.published !== false,
        publishedAt: req.body.publishedAt || new Date(),
      },
      { new: true, runValidators: true },
    );
    if (!blog) return res.status(404).json({ error: "Blog not found" });
    res.json({ blog: publicBlog(blog) });
  }),
);

app.delete(
  "/api/admin/blogs/:id",
  asyncRoute(async (req, res) => {
    const blog = await Blog.findByIdAndDelete(req.params.id);
    if (!blog) return res.status(404).json({ error: "Blog not found" });
    res.json({ ok: true });
  }),
);

app.get(
  "/api/testimonials",
  asyncRoute(async (req, res) => {
    const items = await Testimonial.find({ status: "approved" })
      .sort({ createdAt: -1 })
      .limit(30);
    res.json({ testimonials: items.map(publicTestimonial) });
  }),
);

app.post(
  "/api/testimonials",
  asyncRoute(async (req, res) => {
    const error = requireFields(req.body, ["name", "review"]);
    if (error) return res.status(400).json({ error });
    const review = String(req.body.review).trim();
    if (review.length < 10 || review.length > 1200) {
      return res.status(400).json({ error: "Review must be 10-1200 characters" });
    }
    const testimonial = await Testimonial.create({
      name: String(req.body.name).trim(),
      profileImageUrl: String(req.body.profileImageUrl || "").trim(),
      rating: Math.max(1, Math.min(5, Number(req.body.rating || 5))),
      review,
      status: "pending",
    });
    res.status(201).json({ id: String(testimonial._id), status: testimonial.status });
  }),
);

app.put(
  "/api/admin/testimonials/:id/status",
  asyncRoute(async (req, res) => {
    const status = String(req.body.status || "");
    if (!["pending", "approved", "rejected"].includes(status)) {
      return res.status(400).json({ error: "Invalid testimonial status" });
    }
    const item = await Testimonial.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true },
    );
    if (!item) return res.status(404).json({ error: "Testimonial not found" });
    res.json({ testimonial: publicTestimonial(item), status: item.status });
  }),
);

app.get(
  "/api/app-update",
  asyncRoute(async (req, res) => {
    const update = await getAppUpdateSettings();
    res.json({ update: publicAppUpdate(update) });
  }),
);

app.post(
  "/api/auth/register",
  asyncRoute(async (req, res) => {
    const error = requireFields(req.body, [
      "name",
      "gender",
      "phone",
      "email",
      "place",
      "userType",
      "username",
      "password",
    ]);
    if (error) return res.status(400).json({ error });
    if (String(req.body.password).length < 6) {
      return res.status(400).json({ error: "Password must be at least 6 characters" });
    }
    const username = normalizeUsername(req.body.username);
    if (username.length < 3 || /\s/.test(username)) {
      return res.status(400).json({
        error: "Username must be at least 3 characters and cannot contain spaces",
      });
    }

    const email = normalizeEmail(req.body.email);
    if (!validEmail(email)) {
      return res.status(400).json({ error: "Enter a valid email address" });
    }
    if (!validPhone(req.body.phone)) {
      return res.status(400).json({ error: "Enter a valid mobile number" });
    }
    const existing = await User.findOne({ $or: [{ email }, { username }] });
    if (existing?.email === email) {
      return res.status(409).json({ error: "Email already registered" });
    }
    if (existing?.username === username) {
      return res.status(409).json({ error: "Username already registered" });
    }

    const user = await User.create({
      name: String(req.body.name).trim(),
      gender: String(req.body.gender).trim(),
      email,
      phone: String(req.body.phone || "").trim(),
      place: String(req.body.place).trim(),
      userType: String(req.body.userType).trim(),
      username,
      passwordHash: await bcrypt.hash(String(req.body.password), 12),
      lastLoginAt: new Date(),
    });
    const session = await issueSession(user);
    res.status(201).json({ user: publicUser(user), ...session });
  }),
);

app.post(
  "/api/auth/login",
  asyncRoute(async (req, res) => {
    const error = requireFields(req.body, ["username", "password"]);
    if (error) return res.status(400).json({ error });

    const username = normalizeUsername(req.body.username);
    const user = await User.findOne({
      $or: [{ username }, { email: normalizeEmail(req.body.username) }],
    });
    const matches =
      user && (await bcrypt.compare(String(req.body.password), user.passwordHash));
    if (!matches) return res.status(401).json({ error: "Invalid username or password" });

    user.lastLoginAt = new Date();
    await user.save();
    const session = await issueSession(user);
    res.json({ user: publicUser(user), ...session });
  }),
);

app.post(
  "/api/auth/logout",
  authenticate,
  asyncRoute(async (req, res) => {
    req.session.revokedAt = new Date();
    req.user.lastLogoutAt = new Date();
    await Promise.all([req.session.save(), req.user.save()]);
    res.json({ ok: true });
  }),
);

app.get(
  "/api/me",
  authenticate,
  asyncRoute(async (req, res) => {
    const orders = await Order.find({ userId: req.user._id }).sort({ purchasedAt: -1 });
    res.json({ user: publicUser(req.user), orders: orders.map(publicOrder) });
  }),
);

app.get(
  "/api/remedies",
  asyncRoute(async (req, res) => {
    const remedies = await Remedy.find().sort({ createdAt: 1 });
    res.json({ remedies: remedies.map(publicRemedy) });
  }),
);

app.post(
  "/api/payments/create",
  authenticate,
  asyncRoute(async (req, res) => {
    if (!RAZORPAY_KEY_ID || !RAZORPAY_KEY_SECRET) {
      return res.status(503).json({ error: "Razorpay test keys are not configured" });
    }
    const items = Array.isArray(req.body.items) ? req.body.items : [];
    if (!items.length) return res.status(400).json({ error: "Cart is empty" });
    const inputShipping = req.body.shipping || {};
    const shipping = Object.fromEntries(
      ["name", "phone", "address", "city", "state", "pincode"].map((key) =>
        [key, String(inputShipping[key] || "").trim()]),
    );
    if (Object.values(shipping).some((value) => !value || value.length > 250) ||
        !/^[0-9+() -]{10,16}$/.test(shipping.phone) || !/^\d{6}$/.test(shipping.pincode)) {
      return res.status(400).json({ error: "Valid shipping details are required" });
    }
    const remedyIds = items.map((item) => String(item.remedyId || "").trim());
    const remedies = await Remedy.find({ id: { $in: remedyIds } });
    const remedyById = new Map(remedies.map((item) => [item.id, item]));
    const purchaseItems = [];
    for (const item of items) {
      const remedy = remedyById.get(String(item.remedyId || "").trim());
      if (!remedy) return res.status(404).json({ error: "A cart remedy is unavailable" });
      const quantity = Math.max(1, Math.min(20, Number(item.quantity || 1)));
      purchaseItems.push({
        remedyId: remedy.id,
        remedyName: remedy.title,
        quantity,
        unitPrice: remedy.price,
      });
    }
    const total = purchaseItems.reduce(
      (sum, item) => sum + item.unitPrice * item.quantity,
      0,
    );
    if (total < 1) return res.status(400).json({ error: "Payment total is invalid" });
    const checkoutToken = crypto.randomBytes(32).toString("hex");
    const receipt = `kv_${Date.now()}_${crypto.randomBytes(3).toString("hex")}`;
    const razorpayResponse = await fetch("https://api.razorpay.com/v1/orders", {
      method: "POST",
      headers: {
        Authorization: `Basic ${Buffer.from(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`).toString("base64")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        amount: total * 100,
        currency: "INR",
        receipt,
        notes: { userId: String(req.user._id) },
      }),
      signal: AbortSignal.timeout(10000),
    });
    const razorpayOrder = await razorpayResponse.json().catch(() => ({}));
    if (!razorpayResponse.ok || !razorpayOrder.id) {
      return res.status(502).json({ error: "Unable to start Razorpay payment" });
    }
    const purchase = await Purchase.create({
      userId: req.user._id,
      items: purchaseItems,
      total,
      checkoutTokenHash: hashToken(checkoutToken),
      razorpayOrderId: razorpayOrder.id,
      shipping,
    });
    const origin = `${req.protocol}://${req.get("host")}`;
    let returnUrl = "";
    try {
      const candidate = new URL(String(req.body.returnUrl || ""));
      if (["http:", "https:"].includes(candidate.protocol)) returnUrl = candidate.toString();
    } catch (_) {
      // A missing or malformed return URL keeps the user on the payment receipt.
    }
    res.status(201).json({
      purchaseId: String(purchase._id),
      checkoutUrl: `${origin}/payment/${checkoutToken}${returnUrl ? `?returnUrl=${encodeURIComponent(returnUrl)}` : ""}`,
      amount: total,
      currency: "INR",
      status: purchase.status,
    });
  }),
);

app.get(
  "/api/payments/:id/status",
  authenticate,
  asyncRoute(async (req, res) => {
    const purchase = await Purchase.findOne({ _id: req.params.id, userId: req.user._id });
    if (!purchase) return res.status(404).json({ error: "Purchase not found" });
    const orders = purchase.status === "paid"
      ? await Order.find({ userId: req.user._id, paymentId: purchase.razorpayPaymentId })
      : [];
    res.json({
      status: purchase.status,
      total: purchase.total,
      validityEndsAt: purchase.validityEndsAt || null,
      orders: orders.map(publicOrder),
    });
  }),
);

app.get(
  "/payment/:token",
  asyncRoute(async (req, res) => {
    const purchase = await Purchase.findOne({ checkoutTokenHash: hashToken(req.params.token) })
      .populate("userId");
    if (!purchase) return res.status(404).send("Payment link is invalid.");
    const returnUrl = (() => {
      try {
        const candidate = new URL(String(req.query.returnUrl || ""));
        return ["http:", "https:"].includes(candidate.protocol) ? candidate.toString() : "";
      } catch (_) {
        return "";
      }
    })();
    if (purchase.status === "paid" && returnUrl) return res.redirect(303, returnUrl);
    if (purchase.status === "paid") return res.send("<h2>Payment already completed.</h2><p>You can return to Kubar Vastu.</p>");
    const user = purchase.userId;
    const options = {
      key: RAZORPAY_KEY_ID,
      amount: purchase.total * 100,
      currency: "INR",
      name: "Kubar Vastu",
      description: "One-year remedy purchase",
      order_id: purchase.razorpayOrderId,
      prefill: { name: user.name, email: user.email, contact: user.phone || "" },
      theme: { color: "#9b7428" },
      modal: { confirm_close: true },
    };
    res.type("html").send(`<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"><title>Kubar Vastu Payment</title><script src="https://checkout.razorpay.com/v1/checkout.js"></script><style>body{font-family:system-ui;background:#f5eedd;margin:0;display:grid;place-items:center;min-height:100vh;color:#2a2117}.card{width:min(420px,calc(100% - 32px));background:#fffaf0;border:1px solid #d8bd82;border-radius:18px;padding:26px;box-shadow:0 20px 50px #49371626;text-align:center}button{width:100%;padding:14px;border:0;border-radius:10px;background:#9b7428;color:white;font-weight:800;font-size:16px}.muted{color:#76654f}#status{min-height:24px}</style></head><body><main class="card"><h1>Kubar Vastu</h1><p>One-year remedy validity</p><h2>₹${purchase.total}</h2><p class="muted">Secure payment powered by Razorpay</p><p id="status"></p><button id="pay">Pay Now</button></main><script>const options=${JSON.stringify(options)};const returnUrl=${JSON.stringify(returnUrl)};options.handler=async function(result){document.querySelector('#status').textContent='Verifying payment...';document.querySelector('#pay').disabled=true;const response=await fetch('/api/payments/verify/${req.params.token}',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(result)});const data=await response.json();if(response.ok){document.querySelector('#status').textContent='Payment successful. Opening your purchases...';if(returnUrl){window.location.replace(returnUrl);}else{document.querySelector('#status').textContent='Payment successful. Your remedies are valid for one year. You can return to the app.';document.querySelector('#pay').style.display='none';}}else{document.querySelector('#status').textContent=data.error||'Payment verification failed.';document.querySelector('#pay').disabled=false;}};document.querySelector('#pay').onclick=function(){new Razorpay(options).open();};</script></body></html>`);
  }),
);

app.post(
  "/api/payments/verify/:token",
  asyncRoute(async (req, res) => {
    const purchase = await Purchase.findOne({ checkoutTokenHash: hashToken(req.params.token) });
    if (!purchase) return res.status(404).json({ error: "Purchase not found" });
    if (purchase.status === "paid") return res.json({ ok: true, status: "paid" });
    const paymentId = String(req.body.razorpay_payment_id || "");
    const signature = String(req.body.razorpay_signature || "");
    if (!paymentId || !signature) return res.status(400).json({ error: "Missing payment verification data" });
    const expected = crypto
      .createHmac("sha256", RAZORPAY_KEY_SECRET)
      .update(`${purchase.razorpayOrderId}|${paymentId}`)
      .digest("hex");
    const valid = signature.length === expected.length &&
      crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected));
    if (!valid) return res.status(400).json({ error: "Payment signature is invalid" });
    const paidAt = new Date();
    const validityEndsAt = new Date(paidAt);
    validityEndsAt.setFullYear(validityEndsAt.getFullYear() + 1);
    const existing = await Order.countDocuments({ paymentId });
    if (!existing) {
      await Order.insertMany(
        purchase.items.map((item) => ({
          userId: purchase.userId,
          remedyId: item.remedyId,
          remedyName: item.remedyName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          price: item.unitPrice * item.quantity,
          status: "paid",
          purchasedAt: paidAt,
          validityStartsAt: paidAt,
          validityEndsAt,
          paymentId,
          shipping: purchase.shipping,
        })),
      );
    }
    purchase.status = "paid";
    purchase.razorpayPaymentId = paymentId;
    purchase.paidAt = paidAt;
    purchase.validityEndsAt = validityEndsAt;
    await purchase.save();
    const customer = await User.findById(purchase.userId);
    await sendPurchaseNotification({
      customer,
      items: purchase.items,
      total: purchase.total,
      paymentId,
      status: "paid",
      shipping: purchase.shipping,
    });
    res.json({ ok: true, status: "paid", validityEndsAt });
  }),
);

app.get(
  "/api/admin/overview",
  asyncRoute(async (req, res) => {
    const [users, remedies, orders, appUpdate, blogs, testimonials, videos] = await Promise.all([
      User.find().sort({ createdAt: -1 }),
      Remedy.find().sort({ createdAt: -1 }),
      Order.find().sort({ purchasedAt: -1 }),
      getAppUpdateSettings(),
      Blog.find().sort({ publishedAt: -1 }),
      Testimonial.find().sort({ createdAt: -1 }),
      ContentVideo.find().sort({ publishedAt: -1 }),
    ]);
    const paymentsTotal = orders.reduce((sum, order) => sum + Number(order.price || 0), 0);
    res.json({
      users: users.map(publicUser),
      remedies: remedies.map(publicRemedy),
      orders: orders.map(publicOrder),
      payments: orders.map(publicOrder),
      appUpdate: publicAppUpdate(appUpdate),
      blogs: blogs.map(publicBlog),
      testimonials: testimonials.map(publicTestimonial),
      videos: videos.map(publicVideo),
      stats: {
        users: users.length,
        remedies: remedies.length,
        orders: orders.length,
        paymentsTotal,
        blogs: blogs.length,
        pendingReviews: testimonials.filter((item) => item.status === "pending").length,
        videos: videos.length,
      },
    });
  }),
);

app.get(
  "/api/admin/app-update",
  asyncRoute(async (req, res) => {
    const update = await getAppUpdateSettings();
    res.json({ update: publicAppUpdate(update) });
  }),
);

app.put(
  "/api/admin/app-update",
  asyncRoute(async (req, res) => {
    const latestVersion = String(req.body.latestVersion || "").trim();
    const latestBuildNumber = Number(req.body.latestBuildNumber || 0);
    const downloadUrl = String(req.body.downloadUrl || "").trim();
    const releaseNotes = String(req.body.releaseNotes || "").trim();

    if (!latestVersion) {
      return res.status(400).json({ error: "Latest version is required" });
    }
    if (!Number.isFinite(latestBuildNumber) || latestBuildNumber < 1) {
      return res.status(400).json({ error: "Latest build number must be at least 1" });
    }

    const update = await AppUpdate.findOneAndUpdate(
      { key: "mobile-app" },
      {
        $set: {
          enabled: Boolean(req.body.enabled),
          latestVersion,
          latestBuildNumber,
          downloadUrl,
          releaseNotes,
          forceUpdate: Boolean(req.body.forceUpdate),
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    );

    res.json({ update: publicAppUpdate(update) });
  }),
);

app.post(
  "/api/admin/remedies",
  asyncRoute(async (req, res) => {
    const error = requireFields(req.body, ["title", "direction", "purpose"]);
    if (error) return res.status(400).json({ error });
    const remedy = await Remedy.create(cleanRemedy(req.body));
    res.status(201).json({ remedy: publicRemedy(remedy) });
  }),
);

app.put(
  "/api/admin/remedies/:id",
  asyncRoute(async (req, res) => {
    const error = requireFields(req.body, ["title", "direction", "purpose"]);
    if (error) return res.status(400).json({ error });
    const remedy = await Remedy.findOneAndUpdate(
      { id: req.params.id },
      cleanRemedy(req.body, req.params.id),
      { new: true },
    );
    if (!remedy) return res.status(404).json({ error: "Remedy not found" });
    res.json({ remedy: publicRemedy(remedy) });
  }),
);

app.delete(
  "/api/admin/remedies/:id",
  asyncRoute(async (req, res) => {
    const deleted = await Remedy.findOneAndDelete({ id: req.params.id });
    if (!deleted) return res.status(404).json({ error: "Remedy not found" });
    res.json({ ok: true });
  }),
);

app.post(
  "/api/users",
  asyncRoute(async (req, res) => {
    const error = requireFields(req.body, ["name", "email"]);
    if (error) return res.status(400).json({ error });
    const email = normalizeEmail(req.body.email);
    const password = String(req.body.password || crypto.randomUUID());
    const username = normalizeUsername(req.body.username);
    const setFields = {
      name: String(req.body.name).trim(),
      email,
      gender: String(req.body.gender || "").trim(),
      phone: String(req.body.phone || "").trim(),
      place: String(req.body.place || "").trim(),
      userType: String(req.body.userType || "").trim(),
    };
    if (username) {
      const existingUsername = await User.findOne({ username, email: { $ne: email } });
      if (existingUsername) {
        return res.status(409).json({ error: "Username already registered" });
      }
      setFields.username = username;
    }
    const user = await User.findOneAndUpdate(
      { email },
      {
        $set: setFields,
        $setOnInsert: {
          passwordHash: await bcrypt.hash(password, 12),
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    );
    res.status(201).json({ user: publicUser(user) });
  }),
);

app.get(
  "/api/users",
  asyncRoute(async (req, res) => {
    const user = await User.findOne({ email: normalizeEmail(req.query.email) });
    if (!user) return res.status(404).json({ error: "User not found" });
    res.json({ user: publicUser(user) });
  }),
);

app.post(
  "/api/orders/checkout",
  asyncRoute(async (req, res) => {
    return res.status(410).json({ error: "Use the verified Razorpay payment flow" });
    /* Legacy direct checkout is intentionally unreachable. */
    /* c8 ignore start */
    let user = await userFromBearer(req);
    if (!user) user = await User.findOne({ email: normalizeEmail(req.body.email) });
    if (!user) return res.status(401).json({ error: "Login before checkout" });
    const items = Array.isArray(req.body.items) ? req.body.items : [];
    if (!items.length) return res.status(400).json({ error: "Cart is empty" });
    if (items.length > 30) return res.status(400).json({ error: "Cart has too many items" });
    const remedyIds = items.map((item) => String(item.remedyId || "").trim());
    const remedies = await Remedy.find({ id: { $in: remedyIds } });
    const remedyById = new Map(remedies.map((item) => [item.id, item]));
    const rows = [];
    for (const item of items) {
      const remedy = remedyById.get(String(item.remedyId || "").trim());
      if (!remedy) return res.status(404).json({ error: "A cart remedy is no longer available" });
      const quantity = Math.max(1, Math.min(20, Number(item.quantity || 1)));
      rows.push({
        userId: user._id,
        remedyId: remedy.id,
        remedyName: remedy.title,
        quantity,
        unitPrice: remedy.price,
        price: remedy.price * quantity,
        status: "confirmed",
        purchasedAt: new Date(),
      });
    }
    const orders = await Order.insertMany(rows);
    res.status(201).json({
      orders: orders.map(publicOrder),
      total: orders.reduce((sum, order) => sum + Number(order.price || 0), 0),
    });
    /* c8 ignore stop */
  }),
);

app.post(
  "/api/orders",
  asyncRoute(async (req, res) => {
    const error = requireFields(req.body, ["remedyId"]);
    if (error) return res.status(400).json({ error });

    let user = await userFromBearer(req);
    if (!user) {
      user = await User.findOne({ email: normalizeEmail(req.body.email) });
    }
    if (!user) return res.status(401).json({ error: "Login before purchasing remedies" });

    const remedy = await Remedy.findOne({ id: req.body.remedyId });
    if (!remedy) return res.status(404).json({ error: "Remedy not found" });

    const order = await Order.create({
      userId: user._id,
      remedyId: remedy.id,
      remedyName: remedy.title,
      quantity: 1,
      unitPrice: remedy.price,
      price: remedy.price,
    });
    await sendPurchaseNotification({
      customer: user,
      items: [order],
      total: order.price,
      paymentId: order.paymentId,
      status: order.status,
    });
    res.status(201).json({ order: publicOrder(order) });
  }),
);

app.get(
  "/api/orders",
  asyncRoute(async (req, res) => {
    const user = await User.findOne({ email: normalizeEmail(req.query.email) });
    if (!user) return res.status(404).json({ error: "User not found" });
    const orders = await Order.find({ userId: user._id }).sort({ purchasedAt: -1 });
    res.json({ orders: orders.map(publicOrder) });
  }),
);

app.use((req, res) => res.status(404).json({ error: "Route not found" }));
app.use((error, req, res, next) => {
  if (res.headersSent) return next(error);
  const status = error.name === "ValidationError" ? 400 : 500;
  res.status(status).json({ error: error.message || "Internal server error" });
});

mongoose
  .connect(MONGODB_URI)
  .then(async () => {
    await seedRemedies();
    app.listen(PORT, () => {
      console.log(`Kubar Vastu backend running at http://localhost:${PORT}`);
      console.log(`MongoDB: ${MONGODB_URI}`);
    });
  })
  .catch((error) => {
    console.error("Failed to connect MongoDB:", error.message);
    process.exit(1);
  });
