import dotenv from "dotenv";
dotenv.config();

import { execSync } from "child_process";
import fs from "fs";

let commitSha = "unknown";

// Prefer COMMIT_SHA from Docker/BuildConfig (OpenShift)
if (process.env.NEXT_PUBLIC_COMMIT_SHA) {
  commitSha = process.env.NEXT_PUBLIC_COMMIT_SHA;
} else if (process.env.COMMIT_SHA) {
  commitSha = process.env.COMMIT_SHA;
} else {
  // Fallback to git (for local dev)
  try {
    commitSha = execSync('git rev-parse --short HEAD').toString().trim();
  } catch (e) {
    console.warn("⚠️ No commit SHA found from git, using 'unknown'");
  }
}

console.log("🔖 Commit SHA:", commitSha);

// Write/update .env.local so Next.js can read it
fs.writeFileSync(".env.local", `NEXT_PUBLIC_COMMIT_SHA=${commitSha}\n`, {
  flag: "a", // append if file exists
});

// Always run prisma generate
execSync("prisma generate", { stdio: "inherit" });
