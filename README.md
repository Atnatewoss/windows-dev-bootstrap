## Windows for Developers > *From fresh install to dev-ready in minutes*

I recently had to format and reinstall Windows for the 6th or 7th time. Through all those reinstalls (and a couple of Linux experiments where I corrupted files trying to be smart), I noticed consistent apps and configs I always came back to.

This repo is my **bootstrap script** so that next time I wipe Windows, I'm up and running fast. If you're a developer who wants to get your Windows machine ready for dev work quickly, follow along.

> Most tools are open source. None of this is sponsored (but hey, I'm open to it).

---

## One-command setup

```powershell
# Clone and run (as Administrator)
git clone https://github.com/Atnatewoss/windows-dev-bootstrap.git
cd windows-dev-bootstrap
.\install.ps1
```

**What happens:**
- Checks internet & shows total download size (~1.2 GB)
- Installs all dev tools (Zed, Node, Python, Bun, Obsidian, etc.)
- Pins apps to taskbar
- Removes bloatware (Copilot, Xbox, Teams, etc.) — interactive, you choose

---

## What gets installed

| Category | Tools |
|----------|-------|
| **Editor** | Zed (Rust-based, fast, AI agents) |
| **Browser** | Brave (ad block, RAM efficient) |
| **Runtimes** | Node.js LTS, Python latest, Bun |
| **Notes** | Obsidian |
| **Passwords** | Bitwarden (synced with phone) |
| **File transfer** | LocalSend (laptop ↔ phone) |
| **Version control** | Git + GitHub Desktop |
| **Database** | PostgreSQL + pgAdmin4 |
| **VPN** | ProtonVPN |
| **Terminal** | Windows Terminal (default) |
| **Reminders** | Windows Sticky Notes |

---

## Bloatware removed (by default)

- Copilot & related AI tools
- Clipchamp
- Microsoft News
- Solitaire / casual games
- Xbox Game Bar (keep if you game, toggle off)
- Teams (personal)
- People, Maps, Feedback Hub, Skype, Whiteboard, Power Automate

> The script shows checkboxes, you can keep anything you want.

---

## Repo structure

```
windows-dev-bootstrap/
├── README.md              # This file
├── install.ps1            # Main installer (run as Admin)
├── config.json            # App list + download URLs + sizes
├── remove-bloat.ps1       # Interactive bloatware remover
└── scripts/
    └── (future: pin-to-taskbar, post-config, etc.)
```

---

## Manual steps after script

The script handles installs. You still need to:

1. **Log into Bitwarden** → sync passwords
2. **Log into Brave profiles** → GitHub, Gmail, DeepSeek, Discord, YouTube
3. **Open Obsidian** → restore/pull your vault
4. **Start coding**

---

## Why this exists

Windows is great for development *after* you:
- Install the right tools
- Remove the noise

This repo turns a 2-hour setup into a 15-minute automated run.

---

## Contributing

Found a better tool? A broken link? Open an issue or PR. This is mainly for me, but happy to help others escape reinstall hell.

---

## License

MIT: use it, fork it, improve it.
