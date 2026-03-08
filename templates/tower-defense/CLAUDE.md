# Template: 2D Tower Defense — Claude Code + Godot MCP

> **Status:** Template (not yet battle-tested). Based on patterns from the Zelda-like RPG prototype.
> Copy this folder to start a new tower defense project.

## Project Context

A 2D top-down tower defense game. Enemies follow a path, player places towers to stop them. Think classic Bloons/Kingdom Rush mechanics.

## Tech Stack

- **Engine:** Godot 4.x (GDScript)
- **AI Tooling:** Claude Code + godot-mcp
- **Style:** 16-bit pixel art, top-down

## Architecture

### Core Nodes
- **Tower:** StaticBody2D or Area2D with attack range, fire rate, projectile spawning
- **Enemy:** CharacterBody2D following Path2D/PathFollow2D
- **Projectile:** Area2D with velocity toward target
- **Path:** Path2D + PathFollow2D for enemy movement
- **PlacementGrid:** TileMap or custom grid for valid tower spots
- **HUD:** CanvasLayer with gold, lives, wave counter

### Collision Layers
| Layer | Name | Purpose |
|-------|------|---------|
| 1 | World | Path, boundaries |
| 2 | Towers | Tower bodies (placement collision) |
| 3 | Enemies | Enemy bodies |
| 4 | TowerRange | Tower detection radius |
| 5 | Projectiles | Bullet/arrow hitboxes |

### Key Mechanics
- Wave system: spawn enemies in configurable waves with delays
- Tower placement on grid with gold cost
- Tower targeting: closest, first, strongest
- Projectile system: fire-and-forget or homing
- Gold earned per kill, lives lost when enemy reaches end

## GDScript Conventions

- All comments in Portuguese
- snake_case for variables/functions, PascalCase for nodes/classes
- Type hints on all function signatures
- @export with @export_group() for inspector tuning

## Anti-Patterns
- DO NOT use Godot 3.x syntax
- DO NOT update every enemy's target every frame — use timer-based targeting
- DO NOT hardcode wave data — use exported arrays or resource files
- DO NOT skip `godot --headless --import` for new assets
