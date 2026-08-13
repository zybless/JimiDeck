import { createHash } from "node:crypto";
import { copyFile, mkdir, readFile, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repositoryRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const version = process.argv[2];
const outputRoot = process.argv[3];

if (!version || !outputRoot) {
  throw new Error("Usage: node Scripts/stage_release.mjs <version> <output-directory>");
}

if (!/^\d+\.\d+\.\d+$/.test(version)) {
  throw new Error(`Invalid release version: ${version}`);
}

const artifacts = [
  {
    platform: "macos",
    method: "dmg",
    architecture: "universal",
    source: path.join(repositoryRoot, "dist", `JimiDeck-${version}-Alpha-macOS-universal.dmg`),
    destination: path.join("macos", "dmg", `JimiDeck-${version}-Alpha-macOS-universal.dmg`),
  },
  {
    platform: "macos",
    method: "zip",
    architecture: "universal",
    source: path.join(repositoryRoot, "dist", `JimiDeck-${version}-Alpha-macOS-universal.zip`),
    destination: path.join("macos", "zip", `JimiDeck-${version}-Alpha-macOS-universal.zip`),
  },
  {
    platform: "windows",
    method: "installer",
    architecture: "x64",
    source: path.join(repositoryRoot, "dist", "windows", `JimiDeck-${version}-Alpha-Windows-x64.exe`),
    destination: path.join("windows", "installer", `JimiDeck-${version}-Alpha-Windows-x64.exe`),
  },
  {
    platform: "windows",
    method: "portable",
    architecture: "x64",
    source: path.join(repositoryRoot, "dist", "windows", `JimiDeck-${version}-Alpha-Windows-x64.zip`),
    destination: path.join("windows", "portable", `JimiDeck-${version}-Alpha-Windows-x64.zip`),
  },
];

const downloads = [];
const checksumLines = [];

for (const artifact of artifacts) {
  const destination = path.join(outputRoot, artifact.destination);
  await mkdir(path.dirname(destination), { recursive: true });
  await copyFile(artifact.source, destination);
  const contents = await readFile(destination);
  const sha256 = createHash("sha256").update(contents).digest("hex");
  const metadata = await stat(destination);
  const relativePath = artifact.destination.split(path.sep).join("/");
  checksumLines.push(`${sha256}  ${relativePath}`);
  downloads.push({
    platform: artifact.platform,
    method: artifact.method,
    architecture: artifact.architecture,
    path: relativePath,
    size: metadata.size,
    sha256,
  });
}

await writeFile(path.join(outputRoot, "SHA256SUMS.txt"), `${checksumLines.join("\n")}\n`);
await writeFile(
  path.join(outputRoot, "release.json"),
  `${JSON.stringify({ product: "JimiDeck", version, channel: "alpha", unsigned: true, downloads }, null, 2)}\n`,
);

console.log(`Release upload directory ready: ${outputRoot}`);
