// Crops 1024x1024 2x3 grid images into six 512x512 tiles each.
// Output: server/uploads/products/{slug}-{n}.jpg
const path = require("path");
const fs = require("fs");
const sharp = require("sharp");

const SRC_DIR = "C:/Users/user/Downloads";
const OUT_DIR = path.join(__dirname, "..", "uploads", "products");

const JOBS = [
  { file: "glasses.png", slug: "glasses" },
  { file: "barcelt.png", slug: "bracelet" },
  { file: "app.png", slug: "app" },
];

// 2 cols x 3 rows on a 1024x1024 canvas -> cell 512x512
const CELLS = [
  { n: 1, x: 0,   y: 0   },
  { n: 2, x: 512, y: 0   },
  { n: 3, x: 0,   y: 512 },
  { n: 4, x: 512, y: 512 },
  { n: 5, x: 0,   y: 1024 - 512 }, // overlap-safe: bottom row already covered above
];
// Correct: 3 rows -> y = 0, 341, 682 if exact thirds, but image is 1024 with 2x3 grid where rows are 512? No, 3 rows in 1024 = ~341 each.

// Recompute: 2 columns (1024/2=512 wide) x 3 rows (1024/3≈341 tall)
const COLS = 2;
const ROWS = 3;
const W = Math.floor(1024 / COLS); // 512
const H = Math.floor(1024 / ROWS); // 341

async function run() {
  if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });
  for (const job of JOBS) {
    const srcPath = path.join(SRC_DIR, job.file);
    let n = 1;
    for (let r = 0; r < ROWS; r++) {
      for (let c = 0; c < COLS; c++) {
        const left = c * W;
        const top = r * H;
        const outPath = path.join(OUT_DIR, `${job.slug}-${n}.jpg`);
        await sharp(srcPath)
          .extract({ left, top, width: W, height: H })
          .resize(1500, 1000, { fit: "cover" })
          .jpeg({ quality: 92 })
          .toFile(outPath);
        console.log("wrote", outPath);
        n++;
      }
    }
  }
}
run().catch((e) => { console.error(e); process.exit(1); });
