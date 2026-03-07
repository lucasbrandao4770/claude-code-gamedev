# Claude Code para Game Dev — Zelda-like 2D RPG Prototype

## Project Context

This is a **live demo project** for a 1-hour class titled "Claude Code para Game Dev: Da Ideia ao Protótipo Jogável" for The Plumbers community (Brazilian Data Engineering group). We build a 2D top-down Zelda-like RPG prototype from scratch using Claude Code + Godot MCP.

**Target audience:** Developers (not game devs) who want to learn game dev with AI assistance.

---

## Tech Stack

- **Engine:** Godot 4.x (GDScript)
- **AI Tooling:** Claude Code + Godot MCP (`Coding-Solo/godot-mcp`)
- **Style:** 16-bit pixel art, top-down perspective
- **Assets:** Free packs from itch.io, OpenGameArt, CraftPix

## Godot Path

Godot executable: `D:/Games/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe`

---

## Architecture

### Scene Structure

```
Player (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D
├── SwordHitbox (Area2D + CollisionShape2D) — toggled by animation
└── HurtBox (Area2D + CollisionShape2D)

Slime (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D
├── HurtBox (Area2D + CollisionShape2D)
└── DetectionZone (Area2D + CollisionShape2D)

World (Node2D)
├── TileMap
├── Player
├── Enemies (Node2D)
├── Pickups (Node2D)
└── Camera2D
```

### Collision Layers

| Layer | Name | Purpose |
|-------|------|---------|
| 1 | World | Walls, obstacles, terrain collision |
| 2 | Player | Player body |
| 3 | Enemies | Enemy bodies |
| 4 | PlayerHitbox | Player's sword attack area |
| 5 | EnemyHitbox | Enemy attack/contact damage area |
| 6 | Pickups | Hearts, items on ground |

### Autoloads

| Name | Script | Purpose |
|------|--------|---------|
| GameManager | `autoloads/game_manager.gd` | Player HP, score, game state |
| Events | `autoloads/events.gd` | Signal bus for decoupled communication |

---

## GDScript Conventions

- **All comments in Portuguese** (this is a Brazilian class)
- Use `snake_case` for variables and functions
- Use `PascalCase` for classes and node names
- Always use type hints on function signatures
- Use `@export` for inspector-tunable values
- Use `@onready` for node references
- Prefer signals over direct node references
- Keep scripts small and focused (one responsibility per script)

## File Organization

```
project_root/
├── assets/
│   ├── sprites/player/
│   ├── sprites/enemies/
│   ├── sprites/items/
│   ├── sprites/ui/
│   ├── tilesets/
│   ├── audio/sfx/
│   ├── audio/music/
│   └── fonts/
├── scenes/
│   ├── player/
│   ├── enemies/
│   ├── pickups/
│   ├── ui/
│   └── world/
├── scripts/
│   ├── player/
│   ├── enemies/
│   ├── components/
│   └── autoloads/
└── resources/
```

---

## MVP Scope (What We Build)

### MUST HAVE
- Player: 4-directional movement with walk/idle animations
- Sword attack: slash in facing direction with hitbox
- Slime enemy: wander + chase player when close + contact damage
- Health system: player and enemies have HP
- Damage: flash + knockback + invincibility frames
- Death: enemy death poof, player death → restart
- One map: green field with grass, trees, rocks (TileMap)
- Camera following player
- HUD: hearts display

### SHOULD HAVE
- Background music (chiptune)
- Sound effects (sword, hit, pickup)
- Heart pickups

### NICE TO HAVE
- NPC with dialogue box

### EXPLICITLY OUT OF SCOPE
- Inventory system
- Equipment/drops
- Multiple maps or room transitions
- Save/load
- Menu screens
- Jump mechanic
- Multiple enemy types

---

## Anti-Patterns (DO NOT)

- DO NOT use Godot 3.x syntax — this is Godot 4.x only
- DO NOT use `preload()` in .tres/.tscn files — use `ExtResource()`
- DO NOT use `var`, `const`, `func` in .tres/.tscn files
- DO NOT create overly complex state machines for MVP — simple match/if is fine for slimes
- DO NOT over-engineer — this is a prototype, not production code
- DO NOT skip validation after editing .tres/.tscn files
- DO NOT hardcode paths — use `@export` or `@onready` references
- DO NOT create unnecessary abstractions — 3 similar lines > premature abstraction

---

## Common Patterns

### Hitbox/Hurtbox
```gdscript
# Hitbox (deals damage) — on Player's sword
func _on_area_entered(area: Area2D) -> void:
    if area.has_method("take_damage"):
        area.take_damage(damage)

# Hurtbox (receives damage) — on enemies
func take_damage(amount: int) -> void:
    hp -= amount
    if hp <= 0:
        die()
```

### Signal Bus
```gdscript
# autoloads/events.gd
extends Node
signal player_hit(damage: int)
signal enemy_died(position: Vector2)
```

### Export for Tuning
```gdscript
@export_group("Movimento")
@export var speed: float = 100.0
@export var knockback_force: float = 200.0

@export_group("Combate")
@export var max_hp: int = 3
@export var damage: int = 1
```

---

## Pixel Art Import Settings

When importing pixel art sprites, always set:
- **Filter:** Nearest (not Linear) to preserve crisp pixels
- **Reimport** after changing filter settings

---

## References

- Research reports: `notes/research/`
- Free assets guide: `notes/research/free-2d-rpg-resources-report.md`
- Technical patterns: `notes/research/godot4-zelda-like-rpg-technical-report.md`
- AI tools for Godot: `notes/research/godot-ai-tools-march-2026.md`
