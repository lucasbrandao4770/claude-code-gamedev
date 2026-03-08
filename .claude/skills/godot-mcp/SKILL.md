---
name: godot-mcp
description: >-
  Operational guide for using Godot MCP (godot-mcp) tools correctly. Activate this skill
  whenever calling ANY Godot MCP tool (create_scene, add_node, load_sprite, run_project, etc.),
  setting up a Godot project for MCP use, building scenes programmatically, or running the
  debug loop. Also activate when discussing MCP capabilities/limitations or when a subagent
  is delegated to do MCP scene-building work. Without this skill, Claude will hit silent
  failures — Vector2 properties dropped, load_sprite errors on un-imported assets, orphan
  debug processes. This skill prevents all of them.
---

# Godot MCP Workflow Skill

Proven patterns for using the 14 godot-mcp tools effectively, grounded in source code analysis and real game development sessions. This skill is the operational bridge between Claude Code and the Godot engine — it tells you what works, what silently fails, and the exact sequence to follow.

## Setup

The MCP server needs to find your Godot executable. Detection order:
1. `GODOT_PATH` environment variable (recommended — set this)
2. Platform auto-detection (Program Files, Steam paths, /usr/bin/godot, etc.)

Parameters accept both `camelCase` and `snake_case` (auto-mapped internally): `projectPath` = `project_path`, `scenePath` = `scene_path`, `nodePath` = `node_path`, etc.

## The 14 MCP Tools

| Tool | Params | Status | Critical Notes |
|------|--------|--------|----------------|
| `get_godot_version` | (none) | PASS | Call first to verify MCP connectivity |
| `list_projects` | `directory`, `recursive?` | PASS | Scans for project.godot files |
| `get_project_info` | `projectPath` | PASS | Returns scene/script/asset counts |
| `create_scene` | `projectPath`, `scenePath`, `rootNodeType?` | PASS | Default root: Node2D. Any ClassDB type works |
| `add_node` | `projectPath`, `scenePath`, `nodeType`, `nodeName`, `parentNodePath?`, `properties?` | PASS | Default parent: "root". Nested paths work: `root/HitBox/Shape` |
| `load_sprite` | `projectPath`, `scenePath`, `nodePath`, `texturePath` | CAVEAT | **Requires `godot --headless --import` first** |
| `save_scene` | `projectPath`, `scenePath`, `newPath?` | PASS | `newPath` creates duplicates/variants |
| `launch_editor` | `projectPath` | PASS | Fire-and-forget, no return value |
| `run_project` | `projectPath`, `scene?` | PASS | Kills existing process first, then spawns new one |
| `get_debug_output` | (none) | PASS | Returns `{output: string[], errors: string[]}` |
| `stop_project` | (none) | PASS | Returns final output/errors. Graceful if no process |
| `get_uid` | `projectPath`, `filePath` | CAVEAT | Godot 4.4+ only. Needs editor to generate .uid files first |
| `update_project_uids` | `projectPath` | BROKEN | Double-prefixes path with `res://` — do not use |
| `export_mesh_library` | `projectPath`, `scenePath`, `outputPath`, `meshItemNames?` | LIMITED | MeshInstance3D needs mesh assigned in .tscn first |

### Property Types via `add_node`

| Type | Works? | Example |
|------|--------|---------|
| Boolean | Yes | `position_smoothing_enabled: true` |
| String | Yes | `text: "Hello"` |
| Integer | Yes | `z_index: 5` |
| Vector2, Color, Rect2 | **No** | Silently dropped — set in .tscn or `_ready()` |
| Sub-resources (shapes, meshes) | **No** | Must be defined in .tscn as `[sub_resource]` blocks |

## The Workflow Sequence

Follow this order. Skipping steps causes failures that are hard to diagnose because MCP errors are often silent.

```
 1. Write tool    → create project.godot (or use Godot editor)
 2. Place assets  → copy sprite sheets, audio, fonts into project folder
 3. Bash          → godot --headless --path <project> --import
 4. MCP           → create_scene (one per entity: player, enemy, HUD, world)
 5. MCP           → add_node (build node trees — Sprite2D, CollisionShape2D, etc.)
 6. MCP           → load_sprite (assign textures — ONLY after step 3)
 7. Write tool    → create .gd scripts (MCP cannot create GDScript)
 8. Edit tool     → patch .tscn files (attach scripts, set Vector2, add sub-resources)
 9. MCP           → run_project
10. MCP           → get_debug_output (read errors/prints)
11. MCP           → stop_project
12. Fix           → edit scripts or scenes, then repeat from step 9
```

**Step 3 is the #1 source of failures.** If you skip the headless import, `load_sprite` returns "No loader found for resource." New assets on disk are NOT Godot resources until imported.

## What MCP Cannot Do

Use Claude Code's Write and Edit tools for these — MCP has no equivalent:

- **Create GDScript** (.gd files) — Write tool
- **Create project.godot** — Write tool
- **Attach scripts to nodes** — Edit .tscn to add `[ext_resource]` + `script = ExtResource("id")`
- **Instance sub-scenes** — Use `preload().instantiate()` in GDScript
- **Set complex properties** — Edit .tscn or set in `_ready()`
- **Define collision shapes** — Add `[sub_resource type="CircleShape2D"]` in .tscn
- **Create TileSet/TileMap data** — Write .tscn with inline resources

## Rules

### Always Do

1. **Run `godot --headless --path <project> --import`** after adding ANY new asset files
2. **Call `get_godot_version` at session start** to confirm MCP is connected
3. **Set Vector2/Color/collision layers in .tscn or _ready()** — MCP silently drops them
4. **Define collision shapes as `[sub_resource]` in .tscn** — MCP can't create sub-resources
5. **Use the debug loop**: run → get_debug_output → stop → fix → repeat

### Never Do

1. **Call `load_sprite` on un-imported assets** — fails with "no loader found"
2. **Pass Vector2/Color via `add_node` properties** — silently ignored, no error
3. **Use `update_project_uids`** — broken (creates `res://D:/Workspace/...` paths)
4. **Assume `get_uid` works without editor** — .uid files are editor-generated
5. **Trust MCP for script attachment** — always verify scripts are wired in .tscn

## Collision Layer Convention

When building scenes via MCP + Edit, use these standard layers:

```
Layer 1 (value 1)  = World (walls, terrain)
Layer 2 (value 2)  = Player body
Layer 3 (value 4)  = Enemy bodies
Layer 4 (value 8)  = Player hitbox (sword)
Layer 5 (value 16) = Enemy hitbox (contact damage)
Layer 6 (value 32) = Pickups
```

Set in .tscn: `collision_layer = 2` / `collision_mask = 1`. MCP `add_node` can set integer layer/mask values, but define the shapes as sub-resources via Edit tool.

## Common MCP Sequences

### Create a Character Scene (Player or Enemy)

```
1. create_scene(projectPath=..., scenePath="scenes/player/player.tscn", rootNodeType="CharacterBody2D")
2. add_node(nodeType="Sprite2D", nodeName="Sprite2D", parentNodePath="root", ...)
3. add_node(nodeType="CollisionShape2D", nodeName="CollisionShape2D", parentNodePath="root", ...)
4. add_node(nodeType="Camera2D", nodeName="Camera2D", parentNodePath="root", ...)
5. add_node(nodeType="Area2D", nodeName="HurtBox", parentNodePath="root", ...)
6. add_node(nodeType="CollisionShape2D", nodeName="CollisionShape2D", parentNodePath="root/HurtBox", ...)
7. load_sprite(scenePath=..., nodePath="root/Sprite2D", texturePath="res://assets/sprites/player/idle.png")
8. Write player.gd script
9. Edit .tscn → add ext_resource for script, sub_resource for shapes, set Vector2 properties
```

### Debug Loop

```
1. run_project(projectPath=...)           # kills any existing run automatically
2. [wait a few seconds for game to start]
3. get_debug_output()                     # read errors (no params needed)
4. stop_project()                         # clean up (no params needed)
5. Fix errors in scripts/scenes
6. Repeat from step 1
```

### Duplicate a Scene (Enemy Variant)

```
1. save_scene(projectPath=..., scenePath="res://scenes/enemies/slime.tscn",
              newPath="res://scenes/enemies/slime_strong.tscn")
2. Edit the new .tscn to change properties (HP, speed, color)
```
