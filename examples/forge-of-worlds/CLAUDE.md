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

### Scene Structure (Implemented)

```
Player (CharacterBody2D) — scenes/player/player.tscn
├── Sprite2D (spritesheet-based animation via hframes/vframes)
├── CollisionShape2D (body)
├── Camera2D (follows player, zoom 2x)
├── SwordHitBox (Area2D) — toggled by attack
│   └── CollisionShape2D (disabled by default)
└── HurtBox (Area2D) — receives enemy damage
    └── CollisionShape2D

Slime (CharacterBody2D) — scenes/enemies/slime.tscn
├── Sprite2D (spritesheet-based animation)
├── CollisionShape2D (body)
├── HurtBox (Area2D) — receives sword damage
│   └── CollisionShape2D
├── ContactHitBox (Area2D) — deals contact damage
│   └── CollisionShape2D
└── DetectionZone (Area2D) — aggro range
    └── CollisionShape2D

NPC (Area2D) — scenes/npc/npc.tscn
├── Sprite2D
├── CollisionShape2D (proximity detection)
├── DialogLabel
└── PromptLabel ("[E]")

HUD (CanvasLayer) — scenes/ui/hud.tscn
└── HealthContainer (HBoxContainer) — dynamic heart TextureRects

GameWorld (Node2D) — scenes/world/game_world.tscn
├── Background (ColorRect)
├── Enemies (Node2D) — slime instances
└── NPCs (Node2D) — NPC instances
    (Player, walls, HUD spawned via script)
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
| GameManager | `autoloads/game_manager.gd` | Player HP, score, game state (NOT YET IMPLEMENTED) |
| Events | `autoloads/events.gd` | Signal bus for decoupled communication (NOT YET IMPLEMENTED) |

Currently, state is managed directly in player/slime scripts via signals. Autoloads can be added when the prototype grows.

---

## GDScript Conventions

- **All comments in Portuguese** (this is a Brazilian class)
- Use `snake_case` for variables and functions
- Use `PascalCase` for classes and node names
- Always use type hints on function signatures
- Use `@export` with `@export_group()` for inspector-tunable values
- Use `@onready` for node references
- Prefer signals over direct node references
- Keep scripts small and focused (one responsibility per script)

## Sprite Sheet Conventions

- **CraftPix top-down row order**: DOWN=0, LEFT=1, RIGHT=2, UP=3
- Frame size: 64x64 for player/slime, 32x32 for NPCs
- Player idle UP row has only 4 frames (others have 12) — normalize via constant cycle duration
- Different sheets have different column counts (idle=12, walk=6, attack=8, slime_walk=8)
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

## MVP Scope (What We Build)

### MUST HAVE
- [x] Player: 8-directional movement with walk/idle animations
- [x] Sword attack: slash in facing direction with hitbox
- [x] Slime enemy: wander + chase player when close + contact damage
- [x] Health system: player and enemies have HP
- [x] Damage: flash + knockback + invincibility frames (1s blink)
- [x] Death: enemy death fade, player death → restart
- [ ] One map: green field with grass, trees, rocks (TileMap) — currently ColorRect
- [x] Camera following player
- [x] HUD: hearts display (full/half/empty)

### SHOULD HAVE
- [ ] Background music (chiptune) — assets available in assets/audio/music/
- [ ] Sound effects (sword, hit, pickup) — assets available in assets/audio/sfx/
- [ ] Heart pickups

### NICE TO HAVE
- [x] NPC with dialogue box (pauses game, classic bottom-of-screen panel)
- [x] Damage numbers floating above enemies
- [x] Enemy health bars (green/yellow/red)

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

### Hitbox/Hurtbox (Implemented Pattern)
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

### Dialog System (Implemented Pattern)
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

- Research reports: `notes/research/`
- Free assets guide: `notes/research/free-2d-rpg-resources-report.md`
- Technical patterns: `notes/research/godot4-zelda-like-rpg-technical-report.md`
- AI tools for Godot: `notes/research/godot-ai-tools-march-2026.md`
