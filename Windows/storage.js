const crypto = require("node:crypto");
const fs = require("node:fs/promises");
const path = require("node:path");

async function atomicWrite(destination, contents) {
  await fs.mkdir(path.dirname(destination), { recursive: true });
  const temporary = `${destination}.${crypto.randomUUID()}.tmp`;
  try {
    await fs.writeFile(temporary, contents, { mode: 0o600 });
    await fs.rename(temporary, destination);
  } finally {
    await fs.rm(temporary, { force: true }).catch(() => {});
  }
}

async function readArray(source) {
  const value = JSON.parse(await fs.readFile(source, "utf8"));
  if (!Array.isArray(value)) throw new Error(`${path.basename(source)} 不是有效的列表。`);
  return value;
}

async function loadArrayWithBackup(destination) {
  let primaryError;
  try {
    const values = await readArray(destination);
    await fs
      .access(`${destination}.backup`)
      .catch(() => atomicWrite(`${destination}.backup`, `${JSON.stringify(values, null, 2)}\n`))
      .catch(() => {});
    return { values, recoveredFromBackup: false };
  } catch (error) {
    primaryError = error;
  }

  const backup = `${destination}.backup`;
  try {
    const values = await readArray(backup);
    await atomicWrite(destination, `${JSON.stringify(values, null, 2)}\n`);
    return { values, recoveredFromBackup: true };
  } catch (backupError) {
    if (primaryError.code === "ENOENT" && backupError.code === "ENOENT") {
      return { values: [], recoveredFromBackup: false };
    }
    throw primaryError.code === "ENOENT" ? backupError : primaryError;
  }
}

async function saveArrayWithBackup(destination, values) {
  const contents = `${JSON.stringify(values, null, 2)}\n`;
  await atomicWrite(destination, contents);
  await atomicWrite(`${destination}.backup`, contents).catch(() => {});
}

module.exports = { loadArrayWithBackup, saveArrayWithBackup };
