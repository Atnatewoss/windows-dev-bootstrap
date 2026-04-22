<div align="center">
  <h1>Windows Dev Bootstrap</h1>
  <p><em>From fresh install to fully configured dev environment in one command.</em></p>
  
  [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
  [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

  <br />
  <img src="demo.png" alt="Windows Dev Bootstrap UI" width="800" />
</div>

---

I recently had to format and reinstall Windows for the 6th or 7th time. Through all those reinstalls, I noticed consistent apps and configs I always came back to. This repo turns a 2-hour manual setup into a 10-minute automated run.

If you're a developer who wants to get your Windows machine ready for dev work quickly, follow along.

## Features

- **Zero Dependencies**: Runs completely natively on a fresh Windows install. No Node.js or Python required.
- **Local Web UI**: Automatically boots up a stunning, modern web UI powered by a local PowerShell HTTP server.
- **Smart Installations**: Handles `winget` packages, direct ZIP downloads, auto-extraction, and automatic `PATH` environment updates (e.g., for `Bun`).
- **Real-time Taskbar Pinning**: Automatically pins your selected apps (like Terminal, browsers, and editors) to your taskbar as they install.
- **Secure Credentials**: Enter your Git and PostgreSQL credentials in the UI, and the local script configures them for you. **Nothing ever leaves your machine.**
- **Network Aware**: Performs a speed test to estimate your total download size and time.
- **Offline Cache**: Keeps a local cache of downloaded installers so subsequent runs on the same machine are lightning fast.
- **Import/Export**: Share your custom setup with your team by exporting your selection as a `.json` file.

---

## One-Command Setup

Open **PowerShell as Administrator** and run:

```powershell
irm https://raw.githubusercontent.com/Atnatewoss/windows-dev-bootstrap/main/bootstrap.ps1 | iex
```

**What happens:**
1. Downloads and extracts the latest version of this toolkit to your temp folder.
2. Performs a quick network speed test.
3. Launches a local web server (`localhost:5050`) and opens your default browser.
4. You select your tools, click install, and watch the progress in real-time.
5. Cleans up everything automatically when you close the UI!

---

## What gets installed

The UI allows you to select from curated lists of tools (fully customizable via `config.json`):

| Category | Tools |
|----------|-------------------|
| **Editor** | Zed, VS Code, Cursor, Neovim |
| **Browser** | Brave, Zen, Firefox, Chrome |
| **Runtimes** | Node.js LTS, Python latest, Bun, Deno |
| **Notes** | Obsidian, Notion, Logseq |
| **Passwords** | Bitwarden, 1Password |
| **File transfer** | LocalSend |
| **Version control** | Git, GitHub Desktop |
| **Database** | PostgreSQL + pgAdmin4, MySQL |
| **VPN** | ProtonVPN |
| **Terminal** | Windows Terminal (Pinned automatically) |
| **Reminders** | Windows Sticky Notes |

## Bloatware Removal

You can optionally run a bloatware removal phase that scrubs:
- Copilot & related AI tools
- Clipchamp
- Xbox Game Bar
- Teams (personal)
- *And more...*

---

## Repo Architecture

```text
windows-dev-bootstrap/
├── bootstrap.ps1          # One-liner web-installer
├── launcher.ps1           # Entry point (Checks admin, runs server)
├── server.ps1             # PowerShell backend (HttpListener, Install logic)
├── config.json            # Database of tools (Edit this to add your own!)
└── src/                   # The web UI (HTML/CSS/JS)
```

---

## Contributing

Found a better tool? Want to add a new category? Modifying the toolset is as simple as opening a PR to edit `config.json`. 

If you want to contribute to the core engine, check out `server.ps1` and `src/js/script.js`.

## License

MIT: use it, fork it, improve it. Escape reinstall hell.
