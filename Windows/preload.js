const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("jimiDeck", {
  listInstances: () => ipcRenderer.invoke("instances:list"),
  createInstance: (name) => ipcRenderer.invoke("instances:create", name),
  removeInstance: (profileId) => ipcRenderer.invoke("instances:remove", profileId),
  chooseProject: () => ipcRenderer.invoke("project:choose"),
  launchCLI: (profileId, projectPath) => ipcRenderer.invoke("launch:cli", profileId, projectPath),
  launchDesktop: () => ipcRenderer.invoke("launch:desktop"),
  diagnose: () => ipcRenderer.invoke("environment:diagnose"),
  openChatGPTDownload: () => ipcRenderer.invoke("link:chatgpt")
});
