# Contributing to Windows Dev Bootstrap

First off, thank you for considering contributing! It's people like you that make this tool better for everyone.

## How Can I Help?

### Adding New Tools
The easiest way to contribute is by adding your favorite dev tools to `config.json`.

1. Open `config.json`.
2. Find the appropriate category or create a new one.
3. Add a tool entry:
   ```json
   {
     "name": "Tool Name",
     "recommended": false,
     "iconFile": "tool-icon.svg",
     "method": "winget",
     "id": "Publisher.ToolID",
     "pin_to_taskbar": true
   }
   ```
4. If the tool is not available via `winget`, you can use `direct_download_zip`.
5. Ensure you add a high-quality SVG or WebP icon to `src/icons/`.

### Modifying Bloatware List
If you found more Windows bloat that should be removed, add it to `bloatware.json`.

### Improving the Engine
If you're comfortable with PowerShell or JavaScript, you can help improve the core logic in `server.ps1` or the UI in `src/`.

## Pull Request Process
1. Fork the repo.
2. Create a new branch for your feature or tool.
3. Commit your changes with descriptive messages (e.g., `feat: add Zed editor to config`).
4. Push to your fork and submit a PR.

## Code of Conduct
Please be respectful and constructive in all interactions.

Happy Bootstrapping! 🚀
