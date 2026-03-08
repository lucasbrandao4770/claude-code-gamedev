# Session 5 Report — Forge of Worlds v2 Speedrun

## Overview
Built a complete 2D top-down Zelda-like action RPG prototype from scratch using Claude Code + Godot MCP in a single session.

**Project:** `examples/forge-of-worlds-v2/`
**Engine:** Godot 4.6.1 (Steam)
**Model:** Claude Opus 4.6 (1M context)

## Features Delivered

### MUST HAVE (10/10)
1. Player 4-directional movement with walk/idle animations
2. Sword attack with hitbox (30-70% swing window)
3. Slime enemies: wander/chase AI + contact damage
4. Health system: player (6 HP) and enemies (3 HP)
5. Damage with knockback + invincibility frames (1s blink)
6. Death: enemy death animation + queue_free, player death → restart
7. One map: green field (1920x1080) with invisible wall boundaries
8. Camera following player with position smoothing
9. HUD: 6 hearts display via CanvasLayer
10. Background music (xDeviruchi) + SFX (sword, hurt)

### SHOULD HAVE (2/2)
11. Heart pickups: bobbing animation, coin SFX, heal on contact
12. NPC with dialogue: knight sprite, 3-line English dialogue, game pauses

## Architecture

### Viewport Configuration
- Viewport: 426x240 (3x integer scale to 1278x720)
- Camera zoom: 1x
- Character occupancy: 26.7% of screen height (64px / 240px)
- Research-grounded decision after testing 320x180 (too zoomed) and 640x360 (too distant)

### Collision Layers
| Layer | Bitmask | Name |
|-------|---------|------|
| 1 | 1 | World |
| 2 | 2 | Player |
| 3 | 4 | Enemies |
| 4 | 8 | PlayerHurtbox |
| 5 | 16 | EnemyHurtbox |
| 6 | 32 | PlayerHitbox |
| 7 | 64 | EnemyHitbox |
| 8 | 128 | Pickups |

### Scene Tree
```
GameWorld (Node2D)
├── Background (ColorRect)
├── Boundaries (StaticBody2D + 4 walls)
├── Enemies/
│   ├── Slime1, Slime2, Slime3
├── Pickups/
│   ├── Heart1, Heart2, Heart3
├── NPCs/
│   └── Villager
├── Player (CharacterBody2D)
│   ├── Sprite2D, BodyCollision, SwordHitBox, HurtBox
│   ├── SwordSFX, HurtSFX
│   └── Camera2D
├── HUD (CanvasLayer)
└── Music (AudioStreamPlayer)
```

### Autoloads
- GameManager: HP state, signals, dialog_active flag

## Bugs Encountered & Fixed

| # | Bug | Root Cause | Fix |
|---|-----|-----------|-----|
| 1 | Camera too zoomed (3 iterations) | Wrong viewport size for 64px sprites | Changed to 426x240 viewport with zoom 1x |
| 2 | Slimes don't chase player | Player not in "player" group | Added `add_to_group("player")` in _ready |
| 3 | Sword doesn't hit slimes | SwordHitBox not in "player_hitbox" group | Added `add_to_group("player_hitbox")` in _ready |
| 4 | "Can't change state while flushing queries" | Direct collision shape disable in signal callback | Changed to `set_deferred("disabled", ...)` |
| 5 | Slime directions wrong (RIGHT/LEFT swapped) | Slime sprite rows: DOWN=0, RIGHT=1, LEFT=2, UP=3 | Swapped enum values |
| 6 | Sword hits too early | Hitbox enabled at frame 0 | Delayed to 30-70% of attack cycle |
| 7 | Hearts not intuitive (3 hearts, 6 HP) | 1 heart = 2 HP mapping | Changed to 1 heart = 1 HP (6 hearts) |
| 8 | Music too loud | -10dB too high | Lowered to -20dB |
| 9 | NPC triggers attack animation | "attack" action shared with interaction | Separate "interact" action + GameManager.dialog_active flag |
| 10 | Music stops during NPC dialog | AudioStreamPlayer paused with tree | Set process_mode = PROCESS_MODE_ALWAYS |

## Skills Activated

| Skill | Activations | Helped? |
|-------|------------|---------|
| game-creation | 1 (start) | Yes — structured the 5-phase workflow |
| gdscript | Via subagents | Yes — type hints, export groups, Context7 grounding |
| godot-mcp | Via subagents | Yes — MCP tool sequence, known limitations |
| tscn-editor | Via subagents | Yes — section ordering, property syntax |
| godot | Via subagents | Yes — collision layers, CLI import |

## Subagent Usage

| Agent | Task | Tokens |
|-------|------|--------|
| godot-builder-player | Player scene via MCP | ~28k |
| gdscript-writer-player | Player movement script | ~34k |
| godot-builder-world | World scene + GameManager | ~33k |
| godot-builder-slime | Slime scene + script | ~60k |
| godot-builder-hud | HUD + hearts + GameManager wiring | ~42k |
| gdscript-writer-slime-ui | Damage numbers + health bars | ~30k |
| godot-builder-audio | Music + SFX | ~46k |
| godot-builder-pickups | Heart pickups | ~29k |
| godot-builder-npc | NPC dialogue system | ~33k |
| zoom-research | Camera zoom best practices | ~103k |
| viewport-research | Viewport sizing best practices | ~102k |

## Key Learnings

1. **Viewport sizing matters more than zoom** — for 64px sprites, 320x180 is too small regardless of camera zoom. 426x240 is the sweet spot.
2. **CraftPix sprite packs don't all use the same direction order** — Player uses DOWN/LEFT/RIGHT/UP, Slime uses DOWN/RIGHT/LEFT/UP. Always verify visually.
3. **Group membership is critical for collision detection** — forgetting `add_to_group()` causes silent failures (no errors, just doesn't work).
4. **`set_deferred` is mandatory** for collision shape changes inside signal callbacks.
5. **Shared keybinds need careful input routing** — when J triggers both "attack" and "interact", use a global flag to prevent conflicts.
6. **Audio transforms feel dramatically** — even at -20dB, background music makes the prototype feel like a game instead of a tech demo.

## Commits
1. `57cfe12` — Scaffold: project setup, assets, player movement
2. `7acd855` — Slime enemies, HUD, damage numbers, health bars
3. `d3c9660` — Audio: background music and combat SFX
4. `4c96e0a` — Heart pickups, NPC dialogue, polish
