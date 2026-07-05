## Hey, I'm starlordz12 👋

I use **[Claude Code](https://claude.com/claude-code)** to build genuinely useful tools — mostly where AI meets RC aircraft, hardware, and 3D printing. I bring the real-world problem and the domain knowledge; Claude Code helps me turn it into working software, CAD, and automation, fast.

### 🚁 Featured: `inav-mcp` — talk to your flight controller

[**inav-mcp**](https://github.com/starlordz12/inav-mcp) is an [MCP](https://modelcontextprotocol.io) server I built with Claude Code that lets Claude **configure, diagnose, and troubleshoot an iNAV flight controller over USB** — so you set up a flying wing in plain English instead of memorizing CLI commands.

![Claude discovering a live iNAV flight controller and reading its status over USB](https://raw.githubusercontent.com/starlordz12/inav-mcp/master/assets/demo.gif)

<sub>▶️ Claude finding a live iNAV 6.1.0 flight controller and reading its status over USB.</sub>

- 🛡️ **Safety-first** — every write is dry-run by default, auto-backs-up first, refuses while the board is armed, and reads back to verify.
- 🛩️ Built primarily for **elevon FPV flying wings** (TBS Chupito / Mojito), and conventional planes too.
- 📦 Installable from **PyPI**, MIT-licensed, and CI-tested.

### 🧰 More tools I've built this way

| Project | What it is |
| --- | --- |
| [LocalMeshAI](https://github.com/starlordz12/LocalMeshAI) | Local-first, AI-assisted STL mesh editor for 3D printing: view → orient → edit → export. |
| [Thrust-Vectoring](https://github.com/starlordz12/Thrust-Vectoring) | Dual-axis thrust-vectoring nozzle system for an 80 mm EDF RC jet. |
| [GooSky-S1-V2](https://github.com/starlordz12/GooSky-S1-V2) | EdgeTX/ELRS setup, Lua tools, and docs for the GooSky S1 V2 3D helicopter. |

> ⚙️ Most of these are experimental and move fast — check each repo's README for its current status before relying on it.

### 🧠 How I work

Real hardware problem → design and build it with **Claude Code** → a working, tested tool I actually use.

`Python` · `Blender` · `OpenVSP` · `FastAPI` · `Docker` · `Raspberry Pi` · `MCP` · `EdgeTX / iNAV`

### 📫 Contact

- GitHub: [@starlordz12](https://github.com/starlordz12)
<!-- Add more here if you want: Discord, Reddit, email, personal site, etc. -->
