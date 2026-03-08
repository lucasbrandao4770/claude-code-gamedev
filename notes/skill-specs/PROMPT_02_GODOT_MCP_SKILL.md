# Session Prompt: Build the `godot-mcp` Skill

> Copy-paste this entire file as the first message in a new Claude Code session.
> Working directory: `D:\Workspace\Games\claude-game-dev`

---

## Your Task

Build a Claude Code skill called `godot-mcp` — a **workflow skill for using the Godot MCP (Model Context Protocol) tools** effectively. This skill should activate whenever Claude Code needs to interact with the Godot engine via MCP tools.

## Mandatory Reading (do this FIRST)

Before doing anything else, read these files to understand the context:

1. `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\02-mcp-tool-analysis.md` — Complete tool-by-tool scorecard with capabilities and limitations.
2. `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\03-mistakes-and-fixes.md` — 14 bugs, many MCP-related (load_sprite without import, get_uid needing editor, Vector2 properties dropped silently).
3. `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\05-improvement-suggestions.md` — Suggestions for MCP workflow improvements and wrapper patterns.
4. `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\06-skill-building-notes.md` — Domain 2 covers MCP integration, Domain 5 covers collision system (relevant to MCP setup).
5. `D:\Workspace\Games\claude-game-dev\examples\forge-of-worlds\CLAUDE.md` — The project's CLAUDE.md with the proven MCP workflow pattern.

Also read the godot-mcp README for the latest tool documentation:
- https://github.com/Coding-Solo/godot-mcp

## How This Skill Fits Into the Bigger Picture

We are building a Claude Code setup for AI-assisted game development with Godot. The skill ecosystem is:

| Skill | Level | Purpose |
|-------|-------|---------|
| gdscript (separate skill) | Language | GDScript syntax and patterns |
| godot (exists) | Engine | Godot file formats, architecture |
| **godot-mcp** (THIS ONE) | Tooling | MCP tool usage, limitations, workflow |
| tscn-editor (to be built) | File format | Safe .tscn editing |
| game-creation (to be built) | Workflow | Game creation orchestration |

The godot-mcp skill is the **operational bridge** between Claude Code and the Godot engine. Without it, Claude uses MCP tools blindly and hits known bugs. With it, Claude follows proven patterns and avoids pitfalls.

**Important architectural context:** In our setup, MCP operations are ideally delegated to a specialized **godot-builder subagent**. The main session agent stays lean (orchestrator role) and delegates heavy MCP work. This skill should be written for the AGENT that actually calls MCP tools (whether main or subagent).

## Skill Purpose

Ensure that ALL Godot MCP interactions follow proven patterns, avoid known bugs, and use the correct workflow sequence. The skill acts as an operational manual for the 14 MCP tools.

## Skill Triggers

The skill should activate when:
- Any Godot MCP tool is about to be called
- Creating or modifying Godot scenes programmatically
- Running or debugging a Godot project via MCP
- Setting up a new Godot project for MCP use
- Discussing MCP capabilities or limitations

## Key Content to Include

### The 14 MCP Tools — Quick Reference

| Tool | Status | Key Notes |
|------|--------|-----------|
| `get_godot_version` | PASS | Use first to verify Godot is accessible |
| `list_projects` | PASS | Scans for project.godot files |
| `get_project_info` | PASS | Counts scenes/scripts/assets |
| `create_scene` | PASS | Works with any ClassDB node type |
| `add_node` | PASS | Supports nested paths like `root/HitBox/CollisionShape2D` |
| `load_sprite` | CAVEAT | **REQUIRES `godot --headless --import` first on new assets** |
| `save_scene` | PASS | newPath creates copies |
| `launch_editor` | PASS | Fire-and-forget |
| `run_project` | PASS | Spawns debug process |
| `get_debug_output` | PASS | Returns stdout/stderr arrays |
| `stop_project` | PASS | May return "no process" if already closed |
| `get_uid` | CAVEAT | Needs editor to generate .uid files first |
| `update_project_uids` | BUG | Double-prefixes path — don't use |
| `export_mesh_library` | LIMITED | Needs mesh in .tscn, not just add_node |

### The Critical Workflow Pattern

```
1. Write tool → create project.godot (or better: create project in Godot editor)
2. Place asset files in the project folder
3. Bash → godot --headless --path <project_path> --import
4. MCP → create_scene + add_node (build scene tree)
5. MCP → load_sprite (assign textures — ONLY after step 3)
6. Write tool → create .gd scripts
7. Edit tool → modify .tscn files (attach scripts, set complex properties, add sub-resources)
8. MCP → run_project (launch game)
9. MCP → get_debug_output (read errors)
10. MCP → stop_project (kill game)
11. Fix issues → repeat from step 6 or 7
```

### MUST DO Rules
1. **Always run `godot --headless --path <project> --import` before any `load_sprite` call on new assets.** This is the #1 cause of "no loader found" errors.
2. **Always call `get_godot_version` at session start** to verify MCP connectivity.
3. **Always call `stop_project` before `run_project`** if a previous run might still be active.
4. **Set complex properties (Vector2, Color, collision layers) in .tscn or _ready(), NEVER via MCP `add_node` properties.** They are silently dropped.
5. **Define collision shapes as sub_resources in .tscn files.** MCP `add_node` cannot create sub-resources.
6. **Use the debug loop: run_project → get_debug_output → stop_project → fix → repeat.** This is the core iteration pattern.

### MUST NOT Rules
1. **Never call `load_sprite` on un-imported assets** — will fail with "no loader found."
2. **Never set Vector2/Color/complex types via MCP `add_node` properties parameter** — silently ignored.
3. **Never use `update_project_uids`** — broken (path double-prefix bug).
4. **Never assume `get_uid` works without the editor having run first** — .uid files are generated by the editor.
5. **Never skip the `stop_project` call** — orphan processes can block the next run.

### What MCP CANNOT Do (Use Write/Edit Tools Instead)
- Create GDScript (.gd) files
- Create project.godot
- Attach scripts to scene nodes
- Instance sub-scenes within scenes
- Set complex property types (Vector2, Color, Rect2, etc.)
- Create resource sub-types (CollisionShape2D shapes, meshes, fonts)
- Create TileSet or TileMap data

### Collision Layer Quick Reference
```
Layer 1 (bit 1)  = World (walls, terrain)
Layer 2 (bit 2)  = Player body
Layer 3 (bit 4)  = Enemy bodies
Layer 4 (bit 8)  = Player hitbox (sword)
Layer 5 (bit 16) = Enemy hitbox (contact damage)
Layer 6 (bit 32) = Pickups
```
Set via .tscn: `collision_layer = 2` and `collision_mask = 1`

## Deliverable

Create the skill at: `D:\Workspace\Games\claude-game-dev\.claude\skills\godot-mcp\SKILL.md`

Follow `/skill-creator` best practices:
- Pushy description
- Lean content (under 150 lines)
- Grounded in real experience (reference the bugs and fixes)
- Actionable (every rule has a clear "do this" or "don't do this")

## Quality Check

After creating:
1. Does it clearly list what MCP can and cannot do?
2. Does it mandate the import step before load_sprite?
3. Does it include the debug loop pattern?
4. Does it warn about Vector2 properties being silently dropped?
5. Does it complement (not duplicate) the godot and gdscript skills?
