let categories = [];
let selectedTools = new Set();
let pollInterval = null;
let networkSpeedMbps = 50.0;

// API calls
async function fetchConfig() {
  try {
    const res = await fetch("/api/config");
    if (res.ok) {
      const data = await res.json();
      categories = data.categories;
      initRecommended();
    }
  } catch (err) {
    console.error("Failed to fetch config:", err);
    document.getElementById("statusText").innerText = "error loading config";
  }
}

async function fetchNetworkSpeed() {
  try {
    const res = await fetch("/api/network");
    if (res.ok) {
      const data = await res.json();
      if (data.speed_mbps === "testing") {
        document.getElementById("statusText").innerText = "calculating network speed...";
        setTimeout(fetchNetworkSpeed, 2000);
      } else if (data.speed_mbps) {
        networkSpeedMbps = parseFloat(data.speed_mbps);
        updateStatus();
      }
    }
  } catch (err) {
    console.error("Failed to fetch network speed:", err);
  }
}

async function startInstall(payload) {
  try {
    await fetch("/api/install", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    startPolling();
  } catch (err) {
    addLog(`Failed to start installation: ${err.message}`, "error");
  }
}

async function fetchStatus() {
  try {
    const res = await fetch("/api/status");
    if (res.ok) {
      const status = await res.json();
      return status;
    }
  } catch (err) {
    console.error("Status check failed", err);
  }
  return null;
}

async function exitServer() {
  try {
    await fetch("/api/exit", { method: "POST" });
    window.close(); // Try to close the tab
  } catch (err) {
    // ignore
  }
}

function getIconPath(iconFile) {
  return `icons/${iconFile}`;
}

function getRecommendedSelections() {
  const recs = [];
  categories.forEach((cat) => {
    cat.tools.forEach((tool) => {
      if (tool.recommended) {
        recs.push(`${cat.name}:${tool.name}`);
      }
    });
  });
  return recs;
}

function initRecommended() {
  selectedTools.clear();
  getRecommendedSelections().forEach((key) => selectedTools.add(key));
  render();
}

function render() {
  const container = document.getElementById("mainContent");
  container.innerHTML = "";

  categories.forEach((cat) => {
    const catDiv = document.createElement("div");
    catDiv.className = "category";

    const headerDiv = document.createElement("div");
    headerDiv.className = "category-header";
    headerDiv.innerText = cat.name.toUpperCase();
    catDiv.appendChild(headerDiv);

    const gridDiv = document.createElement("div");
    gridDiv.className = "tool-grid";

    cat.tools.forEach((tool) => {
      const key = `${cat.name}:${tool.name}`;
      const isSelected = selectedTools.has(key);

      const cardDiv = document.createElement("div");
      cardDiv.className = `tool-card ${isSelected ? "selected" : ""}`;

      const iconContainer = document.createElement("div");
      iconContainer.className = "tool-icon-container";

      if (tool.iconFile && tool.iconFile !== "") {
        const img = document.createElement("img");
        img.className = "tool-icon-img";
        img.alt = tool.name;
        img.src = getIconPath(tool.iconFile);
        img.onerror = () => {
          img.style.display = "none";
          const fallback = document.createElement("span");
          fallback.className = "tool-icon-fallback";
          fallback.innerText = "●";
          iconContainer.appendChild(fallback);
        };
        iconContainer.appendChild(img);
      } else {
        const fallback = document.createElement("span");
        fallback.className = "tool-icon-fallback";
        fallback.innerText = "●";
        iconContainer.appendChild(fallback);
      }

      const nameSpan = document.createElement("span");
      nameSpan.className = "tool-name";
      nameSpan.innerText = tool.name;

      cardDiv.appendChild(iconContainer);
      cardDiv.appendChild(nameSpan);

      cardDiv.addEventListener("click", () => {
        if (selectedTools.has(key)) {
          selectedTools.delete(key);
        } else {
          selectedTools.add(key);
        }
        render();
      });

      gridDiv.appendChild(cardDiv);
    });

    catDiv.appendChild(gridDiv);
    container.appendChild(catDiv);
  });

  updateStatus();
}

function updateStatus() {
  const statusText = document.getElementById("statusText");
  const count = selectedTools.size;
  
  if (count === 0) {
    statusText.innerText = "ready";
    return;
  }

  let totalSizeMB = 0;
  const selectedList = Array.from(selectedTools);
  selectedList.forEach(key => {
    const [catName, toolName] = key.split(":");
    const categoryObj = categories.find((c) => c.name === catName);
    const tool = categoryObj?.tools.find((t) => t.name === toolName);
    if (tool) {
      totalSizeMB += tool.size_mb || 100; // default to 100MB if not specified
    }
  });

  const speedMBps = networkSpeedMbps / 8; // Mbps to MB/s
  const estimatedSeconds = speedMBps > 0 ? Math.ceil(totalSizeMB / speedMBps) : 0;
  
  let timeStr = "";
  if (networkSpeedMbps === 0) {
    timeStr = "calculating...";
  } else if (estimatedSeconds < 60) {
    timeStr = `< 1 min`;
  } else {
    const mins = Math.ceil(estimatedSeconds / 60);
    timeStr = `~${mins} mins`;
  }

  const speedInfo = networkSpeedMbps > 0 ? ` (@ ${networkSpeedMbps} Mbps)` : "";
  statusText.innerText = `${count} selected | Est. Size: ${totalSizeMB}MB | Est. Time: ${timeStr}${speedInfo}`;
}

function addLog(message, type = "info", time = null) {
  const logView = document.getElementById("logView");
  const colors = { info: "#8a8aaa", success: "#4aeeaa", error: "#ff6688", warning: "#ffcc66" };
  const entry = document.createElement("div");
  entry.style.color = colors[type] || colors.info;
  const t = time || new Date().toLocaleTimeString();
  entry.innerText = `> ${t} · ${message}`;
  logView.appendChild(entry);
  logView.scrollTop = logView.scrollHeight;
}

let lastLogCount = 0;
function startPolling() {
  if (pollInterval) clearInterval(pollInterval);
  lastLogCount = 0;
  
  pollInterval = setInterval(async () => {
    const status = await fetchStatus();
    if (!status) return;

    const progressFill = document.getElementById("progressFill");
    progressFill.style.width = `${status.progress}%`;
    document.getElementById("installHeader").innerText = `installing... (${status.completed}/${status.total})`;

    if (status.logs && status.logs.length > lastLogCount) {
      for (let i = lastLogCount; i < status.logs.length; i++) {
        const log = status.logs[i];
        addLog(log.message, log.type, log.time);
      }
      lastLogCount = status.logs.length;
    }

    if (!status.isRunning && status.total > 0) {
      clearInterval(pollInterval);
      document.getElementById("installHeader").innerText = "installation complete";
      document.getElementById("closeOverlayBtn").style.display = "block";
    }
  }, 1000);
}

// Event Listeners
document.getElementById("selectRecommendedBtn").addEventListener("click", initRecommended);
document.getElementById("selectAllBtn").addEventListener("click", () => {
  selectedTools.clear();
  categories.forEach((cat) => {
    cat.tools.forEach((tool) => {
      selectedTools.add(`${cat.name}:${tool.name}`);
    });
  });
  render();
});

// Credentials Modal
document.getElementById("runBtn").addEventListener("click", () => {
  if (selectedTools.size === 0) return;
  document.getElementById("credsOverlay").style.display = "flex";
});

document.getElementById("cancelCredsBtn").addEventListener("click", () => {
  document.getElementById("credsOverlay").style.display = "none";
});

document.getElementById("startInstallBtn").addEventListener("click", () => {
  document.getElementById("credsOverlay").style.display = "none";
  
  const payload = {
    tools: Array.from(selectedTools),
    credentials: {
      gitName: document.getElementById("gitName").value,
      gitEmail: document.getElementById("gitEmail").value,
      pgUsername: document.getElementById("pgUsername").value,
      pgPassword: document.getElementById("pgPassword").value,
    }
  };

  const overlay = document.getElementById("overlay");
  const progressFill = document.getElementById("progressFill");
  
  overlay.style.display = "flex";
  document.getElementById("logView").innerHTML = "";
  progressFill.style.width = "0%";
  document.getElementById("installHeader").innerText = "initializing...";
  document.getElementById("closeOverlayBtn").style.display = "none";

  startInstall(payload);
});

document.getElementById("closeOverlayBtn").addEventListener("click", () => {
  exitServer();
  document.getElementById("overlay").style.display = "none";
});

// Export / Import
document.getElementById("exportBtn").addEventListener("click", () => {
  const data = JSON.stringify(Array.from(selectedTools), null, 2);
  const blob = new Blob([data], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "windev-config.json";
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
});

document.getElementById("importBtn").addEventListener("click", () => {
  document.getElementById("importFile").click();
});

document.getElementById("importFile").addEventListener("change", (e) => {
  const file = e.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = (e) => {
    try {
      const parsed = JSON.parse(e.target.result);
      if (Array.isArray(parsed)) {
        selectedTools.clear();
        parsed.forEach(t => selectedTools.add(t));
        render();
      }
    } catch (err) {
      alert("Invalid configuration file.");
    }
  };
  reader.readAsText(file);
});

// Fetch config on load
document.getElementById("username").innerText = "developer";
fetchNetworkSpeed().then(() => {
  fetchConfig();
});
