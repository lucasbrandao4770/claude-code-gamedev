Great idea -- a top-down Zelda-like is a perfect scope for a prototype with Claude Code + Godot MCP. Let me lay out a plan and then we can start building step by step.

---

## Project Plan: Top-Down Action RPG

### Architecture Overview

We need **5 core scenes** to get a playable prototype:

| Scene | Root Node | Purpose |
|-------|-----------|---------|
| `player.tscn` | CharacterBody2D | 8-directional movement, sword attack |
| `slime.tscn` | CharacterBody2D | Enemy AI -- chase, wander, take damage |
| `game_world.tscn` | Node2D | Main scene, spawns player + enemies |
| `hud.tscn` | CanvasLayer | Health hearts display |
| `npc.tscn` | Area2D | (stretch goal) Dialog interaction |

### Combat Design

- **Hitbox/Hurtbox pattern using Area2D** -- never body-to-body collision for damage. The player's sword swing spawns an Area2D hitbox, and enemies have Area2D hurtboxes. This avoids physics conflicts and gives clean damage detection.
- Supplement `area_entered` signals with periodic `get_overlapping_areas()` checks for contact damage (the signal only fires once on initial overlap).

### Collision Layer Plan

| Layer | Name | Used By |
|-------|------|---------|
| 1 | World | Walls, obstacles |
| 2 | Player | Player body |
| 3 | Enemy | Enemy bodies |
| 4 | PlayerHitbox | Sword attack area |
| 5 | EnemyHurtbox | Enemy damage receiver |
| 6 | EnemyHitbox | Enemy contact damage area |
| 7 | PlayerHurtbox | Player damage receiver |

### Sprite Setup Notes (CraftPix 64x64)

Since you have CraftPix top-down sprites, keep in mind:
- **Row order is DOWN=0, LEFT=1, RIGHT=2, UP=3** -- this matters for directional animation.
- Player idle UP row sometimes has fewer frames (4 vs 12) -- we normalize by **cycle duration**, not per-frame delay.
- Slime sheets may differ between Idle (6 columns) and Walk (8 columns), so each animation needs its own SpriteFrames or hframes setting.

---

## Build Order (Step by Step)

Here is the sequence I recommend. Each step produces something testable:

### Step 1: Project Setup
- Create `project.godot` with pixel art settings (nearest-neighbor filtering, 640x360 viewport with 2x-3x stretch).
- Configure `.mcp.json` so the Godot MCP server connects.
- Set up input map: `move_up`, `move_down`, `move_left`, `move_right`, `attack`, `interact`.

### Step 2: Player Scene
- Create `player.tscn` (CharacterBody2D + AnimatedSprite2D + CollisionShape2D).
- Write `player.gd` with 8-directional movement, idle/walk animations, and facing direction tracking.
- Test: player moves around an empty world.

### Step 3: Sword Attack
- Add attack animation and a sword hitbox (Area2D) that activates briefly during the attack.
- Add invincibility frames and knockback logic to the player.
- Test: press attack, see animation, hitbox appears and disappears.

### Step 4: Slime Enemy
- Create `slime.tscn` (CharacterBody2D + AnimatedSprite2D + hurtbox Area2D + hitbox Area2D).
- Write `slime.gd` with simple AI: wander randomly, chase player when nearby, deal contact damage.
- Connect damage signals: player sword hitbox overlaps slime hurtbox = slime takes damage.
- Test: slime wanders, chases, dies after a few hits.

### Step 5: Game World
- Create `game_world.tscn` that instances player and a few slimes.
- Add boundary walls (StaticBody2D with ColorRect or TileMap if we get there).
- Write `game_world.gd` to manage enemy spawning.
- Test: full combat loop works.

### Step 6: HUD
- Create `hud.tscn` (CanvasLayer) showing heart sprites for player HP.
- Connect to player health signal to update display.
- Test: hearts decrease when player takes damage.

### Step 7: Polish (stretch goals)
- NPC with dialog system (pauses game tree, NPC uses `PROCESS_MODE_ALWAYS`).
- Sound effects.
- Heart pickups.
- TileMap for proper terrain.

---

## Workflow We Will Use

For each step, the pattern is:

```
1. Write/Edit tool  -->  project.godot, .gd scripts, .tscn tweaks
2. Bash             -->  godot --headless --import  (after adding new assets)
3. Godot MCP        -->  create_scene, add_node, load_sprite  (scene structure)
4. Write/Edit tool  -->  .gd scripts, attach scripts in .tscn, set Vector2/Color properties
5. Godot MCP        -->  run_project + get_debug_output + stop_project  (test loop)
```

The MCP handles scene tree operations well but cannot create GDScript files or set complex property types (Vector2, Color). We fill those gaps with Claude Code's Write/Edit tools.

---

## What to Do First

Before we write any code, we need to:

1. **Set up the project folder** -- Pick a name and location for the new Godot project.
2. **Organize your CraftPix assets** -- Put sprite sheets into an `assets/sprites/` folder so we can reference them. I need to know which specific packs you have (player, slime, etc.) and the sheet dimensions.
3. **Configure MCP** -- Create `.mcp.json` pointing to your godot-mcp server so we can use the Godot tools.

Once those three things are ready, I will create `project.godot` with the right pixel art settings and input map, then we start building the player scene.

**So -- what would you like to name the project, and can you confirm which CraftPix sprite packs you have (filenames or links)?** That way I can set everything up correctly from the start.
