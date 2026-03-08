# Template: 2D Platformer — Claude Code + Godot MCP

> **Status:** Template (not yet battle-tested). Based on patterns from the Zelda-like RPG prototype.
> Copy this folder to start a new 2D platformer project.

## Project Context

A 2D side-scrolling platformer with pixel art style. Think classic Mario/Celeste mechanics: run, jump, wall-jump, collect items, avoid enemies.

## Tech Stack

- **Engine:** Godot 4.x (GDScript)
- **AI Tooling:** Claude Code + godot-mcp
- **Style:** 16-bit pixel art, side-scrolling

## Architecture

### Core Nodes
- **Player:** CharacterBody2D with gravity, jump, and horizontal movement
- **Enemies:** CharacterBody2D or StaticBody2D depending on type
- **Platforms:** StaticBody2D with CollisionShape2D
- **Pickups:** Area2D for coins, power-ups
- **Camera:** Camera2D with horizontal follow, vertical look-ahead

### Collision Layers
| Layer | Name | Purpose |
|-------|------|---------|
| 1 | World | Platforms, walls, ground |
| 2 | Player | Player body |
| 3 | Enemies | Enemy bodies |
| 4 | PlayerHitbox | Player stomp/attack area |
| 5 | EnemyHitbox | Enemy damage areas |
| 6 | Pickups | Coins, power-ups |

### Key Mechanics
- Gravity + jump with coyote time and jump buffering
- Variable jump height (hold = higher)
- move_and_slide() with is_on_floor() checks
- One-way platforms (set collision to one_way)

## GDScript Conventions

- All comments in Portuguese (for Brazilian audience)
- snake_case for variables/functions, PascalCase for nodes/classes
- Type hints on all function signatures
- @export with @export_group() for inspector tuning

## Anti-Patterns
- DO NOT use Godot 3.x syntax
- DO NOT use body collision for damage — use Area2D
- DO NOT hardcode jump height — use @export
- DO NOT skip `godot --headless --import` for new assets
