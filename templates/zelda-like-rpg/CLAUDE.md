# Template: Top-Down Zelda-like 2D RPG — Claude Code + Godot MCP

> **Template:** Copy this folder to start a new top-down Zelda-like RPG project.
> Based on the battle-tested "Forge of Worlds" prototype.

## Project Context

A 2D top-down Zelda-like RPG prototype built from scratch using Claude Code + Godot MCP.

**Target audience:** Developers (not game devs) who want to learn game dev with AI assistance.

---

## Tech Stack

- **Engine:** Godot 4.x (GDScript)
- **AI Tooling:** Claude Code + Godot MCP (`Coding-Solo/godot-mcp`)
- **Style:** 16-bit pixel art, top-down perspective
- **Assets:** Free packs from itch.io, OpenGameArt, CraftPix (see ASSET-SOURCES.md)

---

## Architecture

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

- **All comments in Portuguese** (for Brazilian audience)
- Use `snake_case` for variables and functions
- Use `PascalCase` for classes and node names
- Always use type hints on function signatures
- Use `@export` with `@export_group()` for inspector-tunable values
- Use `@onready` for node references
- Prefer signals over direct node references
- Keep scripts small and focused (one responsibility per script)

## Sprite Sheet Conventions

- **CraftPix top-down row order**: DOWN=0, LEFT=1, RIGHT=2, UP=3
- Use `hframes`/`vframes` on Sprite2D + manual frame stepping in `_physics_process`
- Animation speed: define total cycle duration, divide by frame count (not fixed per-frame delay)

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

## MVP Scope (What to Build)

### MUST HAVE
- [ ] Player: 8-directional movement with walk/idle animations
- [ ] Sword attack: slash in facing direction with hitbox
- [ ] Slime enemy: wander + chase player when close + contact damage
- [ ] Health system: player and enemies have HP
- [ ] Damage: flash + knockback + invincibility frames (1s blink)
- [ ] Death: enemy death fade, player death → restart
- [ ] One map: green field with grass, trees, rocks (TileMap)
- [ ] Camera following player
- [ ] HUD: hearts display (full/half/empty)

### SHOULD HAVE
- [ ] Background music (chiptune)
- [ ] Sound effects (sword, hit, pickup)
- [ ] Heart pickups

### NICE TO HAVE
- [ ] NPC with dialogue box (pauses game, classic bottom-of-screen panel)
- [ ] Damage numbers floating above enemies
- [ ] Enemy health bars (green/yellow/red)

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
- DO NOT rely solely on `area_entered` for contact damage — use periodic overlap checks too
- DO NOT use body-to-body collision between player and enemies — it causes pushing. Use Area2D for damage
- DO NOT set Vector2/complex properties via MCP `add_node` properties — set in .tscn or `_ready()`
- DO NOT use `load_sprite` before running `godot --headless --import` on new assets
- DO NOT gitignore `.uid` files — they MUST be committed (official Godot requirement)

---

## Common Patterns

### Hitbox/Hurtbox
```gdscript
# Player hurtbox — dual detection: signal + periodic overlap check
func _on_hurtbox_area_entered(area: Area2D) -> void:
    if area.is_in_group("enemy_hitbox"):
        take_damage(1, area.global_position)

func _check_overlapping_damage() -> void:
    for area in hurt_box.get_overlapping_areas():
        if area.is_in_group("enemy_hitbox"):
            take_damage(1, area.global_position)
            return

# Enemy hurtbox — receives sword damage
func take_damage(amount: int) -> void:
    hp -= amount
    _update_health_bar()
    _spawn_damage_number(amount)
    if hp <= 0:
        _die()
```

### Damage with Invincibility Blink
```gdscript
# Knockback curto + invencibilidade longa com piscar
is_hurt = true
damage_cooldown = invincibility_duration
knockback_velocity = (global_position - from_position).normalized() * knockback_force
sprite.modulate = Color(1, 0.3, 0.3)
await get_tree().create_timer(hurt_duration).timeout
is_hurt = false  # libera movimento, mantem invencibilidade via cooldown
# Piscar alpha durante o resto da invencibilidade
```

### Dialog System
```gdscript
# NPC cria CanvasLayer temporario com PanelContainer
# get_tree().paused = true durante dialogo
# Player e NPC usam process_mode = PROCESS_MODE_ALWAYS
# E avanca linhas, ultimo E fecha e despausa
```

### Export for Tuning
```gdscript
@export_group("Movimento")
@export var speed: float = 80.0
@export var knockback_force: float = 250.0

@export_group("Combate")
@export var max_hp: int = 6
@export var attack_damage: int = 1
@export var invincibility_duration: float = 1.0
```

---

## Pixel Art Import Settings

When importing pixel art sprites, always set:
- **Filter:** Nearest (not Linear) to preserve crisp pixels
- **Reimport** after changing filter settings

---

## References

- Free assets guide: see `ASSET-SOURCES.md` in this folder
