# Forge of Worlds v2 — Technical Architecture

## Project Context
2D top-down Zelda-like action RPG prototype. Built with Claude Code + Godot MCP.

## Tech Stack
- **Engine:** Godot 4.x (GDScript)
- **AI Tooling:** Claude Code + godot-mcp
- **Style:** 16-bit pixel art, top-down, 64x64 sprites

## Collision Layers

| Layer # | Bitmask | Name | Purpose |
|---------|---------|------|---------|
| 1 | 1 | World | Walls, map boundaries |
| 2 | 2 | Player | Player CharacterBody2D |
| 3 | 4 | Enemies | Enemy CharacterBody2D |
| 4 | 8 | PlayerHurtbox | Player Area2D receives damage |
| 5 | 16 | EnemyHurtbox | Enemy Area2D receives damage |
| 6 | 32 | PlayerHitbox | Sword Area2D deals damage to enemies |
| 7 | 64 | EnemyHitbox | Enemy contact damage Area2D |
| 8 | 128 | Pickups | Hearts on ground |

### Collision Matrix (layer → mask)
- Player body: layer=2, mask=1+4 (collides with World, stops at walls)
- Enemy body: layer=4, mask=1 (collides with World only — no body-to-body push)
- PlayerHurtbox: layer=8, mask=64 (monitors EnemyHitbox)
- EnemyHurtbox: layer=16, mask=32 (monitors PlayerHitbox)
- PlayerHitbox (sword): layer=32, mask=16 (monitors EnemyHurtbox)
- EnemyHitbox (contact): layer=64, mask=8 (monitors PlayerHurtbox)
- Pickups: layer=128, mask=2 (monitors Player body)

### Collision Matrix
- Player body (layer 2) → collides with World (mask 1), Enemies (mask 3)
- Enemy body (layer 3) → collides with World (mask 1)
- PlayerHurtbox (layer 4) → monitors EnemyHitbox (mask 7)
- EnemyHurtbox (layer 5) → monitors PlayerHitbox (mask 6)
- PlayerHitbox (layer 6) → monitors EnemyHurtbox (mask 5)
- EnemyHitbox (layer 7) → monitors PlayerHurtbox (mask 4)
- Pickups (layer 8) → monitors Player (mask 2)

## Autoloads

| Name | Script | Purpose |
|------|--------|---------|
| GameManager | `scripts/autoloads/game_manager.gd` | Player HP, score, game state, restart |

## Sprite Data (from analyzer)

### Player (Swordsman_lvl1/With_shadow/) — 64x64, 4 rows: DOWN=0, LEFT=1, RIGHT=2, UP=3
| Sheet | Columns | Frames/row | Notes |
|-------|---------|------------|-------|
| Idle | 12 | 12,12,12,4 | UP has only 4 frames — use cycle duration |
| Walk | 6 | 6 all | |
| Attack | 8 | 8 all | |
| Hurt | 5 | 5 all | |
| Death | 7 | 7 all | |

### Slime1 (Slime1/With_shadow/) — 64x64, 4 rows: DOWN=0, RIGHT=1, LEFT=2, UP=3 (NOT same as player!)
| Sheet | Columns | Frames/row |
|-------|---------|------------|
| Idle | 6 | 6 all |
| Walk | 8 | 8 all |
| Attack | 10 | 10 all |
| Hurt | 5 | 5 all |
| Death | 10 | 10 all |

### Animation Speed
Use cycle-based duration (total_time / frame_count), NOT fixed per-frame delay.
Example: 0.8s cycle / 6 frames = 0.133s per frame for Walk.

## GDScript Conventions
- All comments in Portuguese (Brazilian audience)
- `snake_case` for variables/functions, `PascalCase` for classes/nodes
- Type hints on ALL function signatures and exported vars
- `@export` with `@export_group()` for tunable values
- `@onready` for node references
- Prefer signals over direct node references

## MCP Workflow
```
Write tool → project.godot (settings, input map)
Bash → godot --headless --import (after adding assets)
MCP → create_scene + add_node + load_sprite (scene building)
Write tool → .gd scripts
Edit tool → .tscn files (attach scripts, set Vector2/complex props)
MCP → run_project + get_debug_output + stop_project (debug loop)
```

## File Structure
```
forge-of-worlds-v2/
├── project.godot
├── CLAUDE.md
├── GDD.md
├── assets/
│   ├── sprites/player/
│   ├── sprites/enemies/
│   ├── sprites/npcs/
│   ├── audio/music/
│   ├── audio/sfx/
│   └── fonts/
├── scenes/
│   ├── player/
│   ├── enemies/
│   ├── ui/
│   └── world/
├── scripts/
│   ├── player/
│   ├── enemies/
│   ├── world/
│   └── autoloads/
└── resources/
```

## Anti-Patterns (DO NOT)
- DO NOT use body-to-body collision for damage — use Area2D hitbox/hurtbox
- DO NOT rely solely on `area_entered` — add periodic `get_overlapping_areas()` polling
- DO NOT set Vector2/Color via MCP add_node — set in .tscn or _ready()
- DO NOT call load_sprite before `godot --headless --import`
- DO NOT use fixed frame delay with varying frame counts — use cycle duration
- DO NOT skip testing between entities
- DO NOT keep MCP operations in main agent — delegate to subagents
- DO NOT hardcode paths — use @export or @onready
- DO NOT block all input during hurt state — keep stun short (0.3s), invincibility longer (1.0s)
