# Claude Code for Game Dev

> **Da Ideia ao Protótipo Jogável** — From idea to playable prototype using AI

Build game prototypes from scratch using [Claude Code](https://claude.ai/claude-code) + [Godot MCP](https://github.com/Coding-Solo/godot-mcp). This repository contains working examples, genre-specific templates, and research materials for AI-assisted game development.

## What's Inside

### Examples

| Project | Genre | Status | Description |
|---------|-------|--------|-------------|
| [forge-of-worlds](examples/forge-of-worlds/) | Top-Down Action RPG | Working prototype | 2D Zelda-like with player, enemies, NPC dialog, HUD |

### Templates

Start your own project from a genre template. Each includes a pre-configured `CLAUDE.md`, `project.godot`, and curated free asset links.

| Template | Genre | Status |
|----------|-------|--------|
| [zelda-like-rpg](templates/zelda-like-rpg/) | Top-Down Action RPG | Battle-tested |
| [platformer](templates/platformer/) | 2D Side-Scrolling Platformer | Ready to use |
| [tower-defense](templates/tower-defense/) | Top-Down Tower Defense | Ready to use |
| [puzzle](templates/puzzle/) | Grid/Physics Puzzle | Ready to use |

### Research

In-depth research reports in `notes/research/`:
- **GenAI for Game Dev (2026)** — State of AI tools, pricing, limitations
- **Godot AI Tools** — MCP servers, editor plugins, integrations
- **Free 2D RPG Resources** — Asset packs, music, SFX, fonts
- **Community Practices** — Success stories, best practices, common mistakes

## Quick Start

### Prerequisites

- [Godot Engine 4.x](https://godotengine.org/download/) (free)
- [Claude Code](https://claude.ai/claude-code) (requires Anthropic account)
- [Node.js 18+](https://nodejs.org/) (for Godot MCP)
- [godot-mcp](https://github.com/Coding-Solo/godot-mcp) (npm install)

### Start from a Template

```bash
# 1. Clone this repo
git clone https://github.com/lucasbrandao4770/claude-code-gamedev.git

# 2. Copy a template to your workspace
cp -r claude-code-gamedev/templates/zelda-like-rpg/ my-rpg-game/

# 3. Set up MCP
cd my-rpg-game
cp .mcp.json.example .mcp.json
# Edit .mcp.json with your local Godot and godot-mcp paths

# 4. Download assets from ASSET-SOURCES.md

# 5. Start building!
claude
```

### Run the Example

```bash
cd claude-code-gamedev/examples/forge-of-worlds/
cp .mcp.json.example .mcp.json
# Edit .mcp.json with your local paths
# Open in Godot or run via Claude Code + MCP
```

## How It Works

Claude Code uses the Godot MCP to interact directly with the Godot engine:

```
You (natural language) → Claude Code → Godot MCP → Godot Engine
                              ↓
                    Write/Edit GDScript
                    Create/modify scenes
                    Run and debug the game
                    Capture errors and fix them
```

### MCP Workflow

1. **Create scenes** — `create_scene` + `add_node` builds the scene tree
2. **Add visuals** — `load_sprite` assigns textures to sprite nodes
3. **Write code** — Claude writes GDScript files directly
4. **Wire it up** — Edit `.tscn` files to attach scripts and set properties
5. **Test** — `run_project` launches the game, `get_debug_output` captures errors
6. **Iterate** — Fix issues and repeat

## Tools & Resources

| Tool | Purpose | Link |
|------|---------|------|
| Godot Engine | Game engine (free, open source) | [godotengine.org](https://godotengine.org/) |
| Claude Code | AI coding assistant | [claude.ai](https://claude.ai/claude-code) |
| godot-mcp | MCP bridge for Godot | [GitHub](https://github.com/Coding-Solo/godot-mcp) |
| PixelLab | AI pixel art generation | [pixellab.ai](https://www.pixellab.ai/) |
| Suno | AI music generation | [suno.com](https://suno.com/) |
| jsfxr | Retro sound effect generator | [sfxr.me](https://sfxr.me/) |
| Kenney Assets | Free game assets (CC0) | [kenney.nl](https://kenney.nl/) |
| CraftPix | Free pixel art assets | [craftpix.net](https://craftpix.net/freebies/) |
| OpenGameArt | Community game assets | [opengameart.org](https://opengameart.org/) |

## Context

This project was created for a workshop at **The Plumbers** (Brazilian Data Engineering community). The lesson demonstrates how developers with zero game dev experience can use Claude Code + Godot MCP to build a playable game prototype in under an hour.

## License

Code and templates are MIT licensed. Game assets have individual licenses — see `CREDITS.md` and `ASSET-SOURCES.md` in each example/template for details.
