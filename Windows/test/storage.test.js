const assert = require("node:assert/strict");
const fs = require("node:fs/promises");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");
const { loadArrayWithBackup, saveArrayWithBackup } = require("../storage");

test("returns an empty list when storage does not exist", async () => {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), "jimideck-storage-"));
  try {
    const result = await loadArrayWithBackup(path.join(directory, "instances.json"));
    assert.deepEqual(result, { values: [], recoveredFromBackup: false });
  } finally {
    await fs.rm(directory, { recursive: true, force: true });
  }
});

test("recovers a corrupt primary file from backup", async () => {
  const directory = await fs.mkdtemp(path.join(os.tmpdir(), "jimideck-storage-"));
  const destination = path.join(directory, "instances.json");
  const instances = [{ profileId: "jimideck-cli-test" }];
  try {
    await saveArrayWithBackup(destination, instances);
    await fs.writeFile(destination, "not-json");
    const result = await loadArrayWithBackup(destination);
    assert.deepEqual(result, { values: instances, recoveredFromBackup: true });
    assert.deepEqual(JSON.parse(await fs.readFile(destination, "utf8")), instances);
  } finally {
    await fs.rm(directory, { recursive: true, force: true });
  }
});
