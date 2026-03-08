# Claude Code for Game Dev

## Repository Overview

This is a teaching resource and portfolio project for using Claude Code + Godot MCP to build game prototypes from scratch. Created for the lesson "Claude Code para Game Dev: Da Ideia ao Protótipo Jogável" for The Plumbers community.

## Structure

- `examples/` — Complete, working game prototypes built with Claude Code + Godot MCP
- `templates/` — Genre-specific starter kits (CLAUDE.md, project.godot, asset sources) for students to begin their own projects
- `notes/research/` — Grounding research reports on GenAI for game dev, Godot AI tools, free assets, community practices
- `presentation/` — Lesson materials and branding

## Tech Stack

- **Engine:** Godot 4.x (GDScript)
- **AI Tooling:** Claude Code + godot-mcp (https://github.com/Coding-Solo/godot-mcp)
- **Asset Style:** 16-bit pixel art, top-down perspective

## Working with Examples

Each `examples/{game}/` folder is a self-contained Godot project. To use one:
1. Copy the folder to your workspace
2. Create `.mcp.json` from `.mcp.json.example` with your local paths
3. Open in Godot or use Claude Code + Godot MCP

## Working with Templates

Each `templates/{genre}/` folder contains:
- `CLAUDE.md` — Pre-configured Claude context for that game genre
- `project.godot` — Godot project with pixel art settings, input maps, collision layers
- `.mcp.json.example` — MCP configuration template
- `ASSET-SOURCES.md` — Curated list of free assets with download links and licenses

To start a new project from a template:
1. Copy the template folder to your workspace
2. Rename it to your project name
3. Create `.mcp.json` from `.mcp.json.example`
4. Download assets from `ASSET-SOURCES.md`
5. Start Claude Code and begin building!

## Key Learnings from Development

### MCP Workflow Pattern
```
Write tool → project.godot
Bash → godot --headless --import (for new assets)
MCP → create_scene + add_node + load_sprite (scene structure)
Write tool → .gd scripts
Edit tool → .tscn files (attach scripts, set complex properties)
MCP → run_project + get_debug_output + stop_project (debug loop)
```

### What the MCP Can/Cannot Do
- CAN: create scenes, add nodes, load sprites, run/stop project, capture debug output
- CANNOT: create GDScript, create project.godot, attach scripts, set Vector2/complex properties, instance sub-scenes
- The gap is filled by Claude Code's Write/Edit tools

### Critical Rules
- Run `godot --headless --import` after adding new asset files
- Use Area2D for damage, never body-to-body collision between player/enemies
- Use periodic `get_overlapping_areas()` alongside `area_entered` for contact damage
- Set complex properties (Vector2, Color) in .tscn or _ready(), not via MCP
- Commit `.uid` and `.import` sidecar files to git
- Normalize animation speed by cycle duration, not per-frame delay
