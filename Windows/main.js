const { app, BrowserWindow, dialog, ipcMain, shell } = require("electron");
const { execFile, spawn } = require("node:child_process");
const fs = require("node:fs/promises");
const os = require("node:os");
const path = require("node:path");
const { promisify } = require("node:util");
const crypto = require("node:crypto");

const execFileAsync = promisify(execFile);
const profilePattern = /^jimideck-cli-[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function instancesFile() {
  return path.join(app.getPath("userData"), "instances.json");
}

function profileHome(profileId) {
  return profileId === "default"
    ? path.join(os.homedir(), ".codex")
    : path.join(os.homedir(), `.codex-${profileId}`);
}

function isManaged(profileId) {
  return profilePattern.test(profileId);
}

async function loadInstances() {
  try {
    const values = JSON.parse(await fs.readFile(instancesFile(), "utf8"));
    return Array.isArray(values) ? values.filter((value) => isManaged(value.profileId)) : [];
  } catch (error) {
    if (error.code === "ENOENT") return [];
    throw error;
  }
}

async function saveInstances(values) {
  const destination = instancesFile();
  await fs.mkdir(path.dirname(destination), { recursive: true });
  const temporary = `${destination}.${crypto.randomUUID()}.tmp`;
  await fs.writeFile(temporary, `${JSON.stringify(values, null, 2)}\n`, { mode: 0o600 });
  await fs.rename(temporary, destination);
}

function safeManagedHome(profileId) {
  if (!isManaged(profileId)) throw new Error("拒绝操作非 JimiDeck 管理的 Profile。");
  const home = path.resolve(profileHome(profileId));
  const parent = path.resolve(os.homedir());
  if (path.dirname(home).toLowerCase() !== parent.toLowerCase()) {
    throw new Error("Profile 路径超出用户目录，已拒绝操作。");
  }
  return home;
}

async function createProfile(displayName) {
  const name = String(displayName || "").trim();
  if (!name) throw new Error("请输入实例名称。");
  const profileId = `jimideck-cli-${crypto.randomUUID()}`;
  const home = safeManagedHome(profileId);
  await fs.mkdir(home, { recursive: false, mode: 0o700 });
  const instance = {
    id: crypto.randomUUID(),
    displayName: name,
    type: "cli",
    profileId,
    createdAt: new Date().toISOString()
  };

  try {
    const instances = await loadInstances();
    instances.push(instance);
    await saveInstances(instances);
    return instance;
  } catch (error) {
    await fs.rm(home, { recursive: true, force: true });
    throw error;
  }
}

async function removeProfile(profileId) {
  const home = safeManagedHome(profileId);
  try {
    const stat = await fs.lstat(home);
    if (stat.isSymbolicLink()) throw new Error("拒绝删除符号链接 Profile。");
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }

  const instances = await loadInstances();
  await fs.rm(home, { recursive: true, force: true });
  await saveInstances(instances.filter((instance) => instance.profileId !== profileId));
}

function spawnPowerShell(argumentsList, options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn("powershell.exe", argumentsList, {
      detached: true,
      stdio: "ignore",
      windowsHide: false,
      ...options
    });
    child.once("spawn", () => {
      child.unref();
      resolve();
    });
    child.once("error", reject);
  });
}

async function launchCLI(profileId, projectPath) {
  if (profileId !== "default" && !isManaged(profileId)) {
    throw new Error("无效的 CLI Profile。");
  }
  const home = profileHome(profileId);
  await fs.mkdir(home, { recursive: true, mode: 0o700 });
  await spawnPowerShell(["-NoLogo", "-NoExit", "-Command", "codex"], {
    cwd: projectPath,
    env: { ...process.env, CODEX_HOME: home }
  });
}

async function launchDesktop() {
  const script = [
    "$entry = Get-StartApps | Where-Object { $_.Name -match '^ChatGPT$|ChatGPT' } | Select-Object -First 1",
    "if (-not $entry) { throw '未找到 ChatGPT Windows App，请先从 Microsoft Store 安装。' }",
    "Start-Process explorer.exe -ArgumentList ('shell:AppsFolder\\' + $entry.AppID)"
  ].join("; ");
  const encoded = Buffer.from(script, "utf16le").toString("base64");
  await spawnPowerShell(["-NoProfile", "-EncodedCommand", encoded], { windowsHide: true });
}

async function diagnose() {
  const result = { cliFound: false, cliPath: "—", desktopFound: false };
  try {
    const { stdout } = await execFileAsync(
      "powershell.exe",
      ["-NoProfile", "-Command", "(Get-Command codex -ErrorAction Stop).Source"],
      { windowsHide: true }
    );
    result.cliFound = true;
    result.cliPath = stdout.trim();
  } catch {}

  try {
    const { stdout } = await execFileAsync(
      "powershell.exe",
      [
        "-NoProfile",
        "-Command",
        "[bool](Get-StartApps | Where-Object { $_.Name -match '^ChatGPT$|ChatGPT' } | Select-Object -First 1)"
      ],
      { windowsHide: true }
    );
    result.desktopFound = stdout.trim().toLowerCase() === "true";
  } catch {}
  return result;
}

function createWindow() {
  const window = new BrowserWindow({
    width: 920,
    height: 720,
    minWidth: 720,
    minHeight: 560,
    backgroundColor: "#f5f7f6",
    icon: path.join(__dirname, "assets", "icon.png"),
    title: "JimiDeck",
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true
    }
  });
  window.removeMenu();
  window.loadFile(path.join(__dirname, "renderer", "index.html"));
}

app.whenReady().then(() => {
  ipcMain.handle("instances:list", loadInstances);
  ipcMain.handle("instances:create", (_, name) => createProfile(name));
  ipcMain.handle("instances:remove", (_, profileId) => removeProfile(profileId));
  ipcMain.handle("project:choose", async () => {
    const result = await dialog.showOpenDialog({ properties: ["openDirectory", "createDirectory"] });
    return result.canceled ? null : result.filePaths[0];
  });
  ipcMain.handle("launch:cli", (_, profileId, projectPath) => launchCLI(profileId, projectPath));
  ipcMain.handle("launch:desktop", launchDesktop);
  ipcMain.handle("environment:diagnose", diagnose);
  ipcMain.handle("link:chatgpt", () => shell.openExternal("ms-windows-store://pdp/?ProductId=9PLM9XGG6VKS"));
  createWindow();
});

app.on("window-all-closed", () => app.quit());
