const cards = document.querySelector("#cards");
const notice = document.querySelector("#notice");
const createDialog = document.querySelector("#create-dialog");
const settingsDialog = document.querySelector("#settings-dialog");
const settingsContent = document.querySelector("#settings-content");

let instances = [];
let diagnostics = { cliFound: false, cliPath: "—", desktopFound: false };

function showError(error) {
  const message = error?.message || String(error);
  notice.textContent = message.replace(
    /^Error invoking remote method '[^']+': Error: /,
    ""
  );
  notice.classList.remove("hidden");
}

function clearError() {
  notice.classList.add("hidden");
  notice.textContent = "";
}

function card({ displayName, type, profileId, subtitle }) {
  const button = document.createElement("button");
  button.className = "card";
  button.innerHTML = `<span class="card-icon">${type === "desktop" ? "▣" : "&gt;_"}</span><span><strong></strong><small></small></span><span class="arrow">›</span>`;
  button.querySelector("strong").textContent = displayName;
  button.querySelector("small").textContent = subtitle;
  button.addEventListener("click", async () => {
    clearError();
    try {
      if (type === "desktop") {
        if (!diagnostics.desktopFound) {
          await window.jimiDeck.openChatGPTDownload();
          return;
        }
        await window.jimiDeck.launchDesktop();
      } else {
        if (!diagnostics.cliFound) {
          throw new Error("未检测到 codex 命令，请先安装 Codex CLI 并将其加入 PATH。");
        }
        const projectPath = await window.jimiDeck.chooseProject();
        if (projectPath) await window.jimiDeck.launchCLI(profileId, projectPath);
      }
    } catch (error) {
      showError(error);
    }
  });
  return button;
}

function renderCards() {
  cards.replaceChildren();
  cards.append(
    card({
      displayName: "Default Desktop",
      type: "desktop",
      profileId: "default",
      subtitle: diagnostics.desktopFound ? "系统 ChatGPT Desktop" : "未检测到 ChatGPT Windows App"
    }),
    card({
      displayName: "Default CLI",
      type: "cli",
      profileId: "default",
      subtitle: diagnostics.cliFound ? "系统 Codex CLI" : "未检测到 codex 命令"
    })
  );
  for (const instance of instances) {
    cards.append(card({ ...instance, subtitle: "独立 Codex CLI Profile" }));
  }
}

async function refresh() {
  clearError();
  try {
    [instances, diagnostics] = await Promise.all([
      window.jimiDeck.listInstances(),
      window.jimiDeck.diagnose()
    ]);
    renderCards();
  } catch (error) {
    showError(error);
  }
}

document.querySelector("#create-button").addEventListener("click", () => {
  document.querySelector("#instance-name").value = "";
  createDialog.showModal();
  document.querySelector("#instance-name").focus();
});

createDialog.querySelector(".close-button").addEventListener("click", () => createDialog.close());
document.querySelector("#create-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  try {
    await window.jimiDeck.createInstance(document.querySelector("#instance-name").value);
    createDialog.close();
    await refresh();
  } catch (error) {
    showError(error);
  }
});

function renderSettings(section) {
  if (section === "instances") {
    settingsContent.innerHTML = `<h2 class="settings-title">实例管理</h2>`;
    if (!instances.length) {
      settingsContent.insertAdjacentHTML("beforeend", "<p>没有自建 CLI 实例。</p>");
      return;
    }
    for (const instance of instances) {
      const row = document.createElement("div");
      row.className = "settings-row";
      row.innerHTML = `<div><strong></strong><div class="profile-id"></div></div><button class="danger">删除</button>`;
      row.querySelector("strong").textContent = instance.displayName;
      row.querySelector(".profile-id").textContent = instance.profileId;
      row.querySelector("button").addEventListener("click", async () => {
        if (!confirm(`永久删除“${instance.displayName}”及其本地登录状态？`)) return;
        try {
          await window.jimiDeck.removeInstance(instance.profileId);
          instances = await window.jimiDeck.listInstances();
          renderCards();
          renderSettings("instances");
        } catch (error) {
          showError(error);
        }
      });
      settingsContent.append(row);
    }
  } else if (section === "diagnostics") {
    settingsContent.innerHTML = `
      <h2 class="settings-title">环境诊断</h2>
      <div class="diagnostic"><span>JimiDeck</span><span>正常</span></div>
      <div class="diagnostic"><span>ChatGPT Desktop</span><span>${diagnostics.desktopFound ? "已安装" : "未检测到"}</span></div>
      <div class="diagnostic"><span>Codex CLI</span><span>${diagnostics.cliFound ? "已安装" : "未检测到"}</span></div>
      <div class="diagnostic"><span>CLI 路径</span><span class="profile-id">${diagnostics.cliPath}</span></div>
      <p class="platform-note">Windows Desktop 自定义多实例没有公开稳定接口；当前 Alpha 仅启动系统默认 Desktop。</p>`;
  } else {
    settingsContent.innerHTML = `<div class="about"><img src="../assets/icon.png" alt=""><h2>JimiDeck</h2><p>Codex Instance Manager</p><p>Version 0.1.0 Alpha</p><p>© 2026 JimiDeck</p></div>`;
  }
}

document.querySelector("#settings-button").addEventListener("click", async () => {
  await refresh();
  renderSettings("instances");
  settingsDialog.showModal();
});
settingsDialog.querySelector(".close-button").addEventListener("click", () => settingsDialog.close());
for (const button of settingsDialog.querySelectorAll("nav button")) {
  button.addEventListener("click", () => {
    settingsDialog.querySelector("nav .selected").classList.remove("selected");
    button.classList.add("selected");
    renderSettings(button.dataset.section);
  });
}

refresh();
