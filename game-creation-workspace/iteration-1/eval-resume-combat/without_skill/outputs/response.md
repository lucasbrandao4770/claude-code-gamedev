Great -- you have a solid foundation with the CharacterBody2D player already moving in 8 directions. Here is the plan broken into three phases, each building on the last. I will implement them one at a time so we can test after each step.

---

## Phase 1: Slime Enemy with Chase AI

**New scene: `slime.tscn`**

Node structure:
```
CharacterBody2D (Slime)
  +-- Sprite2D           (slime spritesheet)
  +-- CollisionShape2D   (physics body - CircleShape2D)
  +-- Area2D (Hurtbox)   (receives damage)
  |     +-- CollisionShape2D
  +-- Area2D (Hitbox)    (deals contact damage to player)
  |     +-- CollisionShape2D
  +-- Timer (ChaseTimer) (periodic retarget / state update)
```

**Script: `slime.gd`**

- **States:** IDLE, CHASE
- In `_physics_process`: if the player is within a detection radius (~120px), switch to CHASE and move toward the player at a set speed (e.g. 40 px/s). Otherwise, IDLE (wander or stand still).
- Flip the sprite based on movement direction.
- Health variable (e.g. `var hp: int = 3`).
- A `take_damage(amount)` function that decrements HP, flashes the sprite white briefly (modulate), and destroys the slime when HP <= 0.
- The Hitbox Area2D will be used in Phase 3 to deal contact damage to the player.

**Why Area2D for combat instead of body collision?** Using body-to-body collision between two CharacterBody2D nodes causes physics pushing and unreliable signals. The hitbox/hurtbox pattern with Area2D is the standard Godot approach -- `area_entered` fires cleanly without physics side effects.

---

## Phase 2: Sword Attack for the Player

**Modify: `player.tscn`**

Add these nodes to the existing player scene:
```
(existing CharacterBody2D)
  +-- ... existing nodes ...
  +-- Area2D (SwordHitbox)      (deals damage to enemies)
  |     +-- CollisionShape2D    (rectangular, offset in front of player)
  +-- AnimationPlayer           (attack animation timing)
  +-- Timer (AttackCooldown)    (prevents spam, e.g. 0.4s)
```

**Modify: `player.gd`**

- Add an `attack()` function triggered by an input action (e.g. "attack" mapped to Space or Z key).
- On attack press:
  1. Check cooldown timer -- if still running, ignore.
  2. Set `is_attacking = true`, start the cooldown timer.
  3. Position the SwordHitbox in front of the player based on `last_direction` (the facing direction). For 4 cardinal + 4 diagonal directions, set the CollisionShape2D's `position` accordingly (e.g. facing right = offset `Vector2(20, 0)`, facing up-right = `Vector2(14, -14)`).
  4. Enable the SwordHitbox collision, wait ~0.15s (via AnimationPlayer or a short timer), then disable it.
  5. Optionally animate the sprite or play a slash visual effect.
- The SwordHitbox Area2D will detect overlapping enemy Hurtbox areas and call `take_damage()` on them.

**Input map update:** Add `"attack"` action to `project.godot` mapped to the key of your choice.

---

## Phase 3: Combat System (Mutual Damage)

**Player takes damage:**

Add to `player.tscn`:
```
(existing CharacterBody2D)
  +-- ... existing nodes ...
  +-- Area2D (PlayerHurtbox)    (receives damage from enemies)
  |     +-- CollisionShape2D
```

**Modify: `player.gd`**

- Add `var hp: int = 5` and `var invincible: bool = false`.
- Add `take_damage(amount)` function:
  1. If `invincible`, return.
  2. Decrement HP.
  3. Set `invincible = true`, start an invincibility timer (~1.0s). Flash/blink the sprite via modulate alpha toggle.
  4. Apply knockback: brief velocity impulse away from the damage source.
  5. If HP <= 0, trigger death (reload scene or show game over).
- Connect the PlayerHurtbox's `area_entered` signal: when a slime's Hitbox overlaps, call `take_damage(1)`.
- Also add a periodic check using `get_overlapping_areas()` on the PlayerHurtbox -- `area_entered` only fires once on initial overlap, so if the player stays in contact with a slime, the periodic check ensures continued damage ticks (e.g. every 0.5s via a Timer).

**Sword hits enemies:**

- In `player.gd`, connect the SwordHitbox's `area_entered` signal.
- When it overlaps an area whose parent has a `take_damage` method, call `enemy.take_damage(1)`.

**Collision layer setup in `project.godot`:**

| Layer | Name       | Usage                          |
|-------|------------|--------------------------------|
| 1     | Physics    | Player and Slime body collision (walls, environment) |
| 2     | PlayerHurt | Player's Hurtbox               |
| 3     | EnemyHurt  | Slime's Hurtbox                |
| 4     | PlayerAtk  | Sword Hitbox                   |
| 5     | EnemyAtk   | Slime's Hitbox                 |

Mask configuration:
- **SwordHitbox (layer 4)** masks layer 3 (detects enemy hurtboxes)
- **Slime Hitbox (layer 5)** masks layer 2 (detects player hurtbox)
- **PlayerHurtbox (layer 2)** masks layer 5 (detected by enemy attacks)
- **Slime Hurtbox (layer 3)** masks layer 4 (detected by sword)

This ensures the sword only hits enemies and slime contact only hits the player -- no friendly fire, no self-detection.

---

## Implementation Order

I recommend we build and test in this order:

1. **Slime scene + chase AI** -- spawn it in the game world, verify it chases the player.
2. **Sword attack on player** -- verify the hitbox activates and we can see it (enable debug collisions in Godot).
3. **Wire up damage** -- sword kills slimes, slime contact hurts player, knockback + invincibility frames work.

Each step, we will use `run_project` and `get_debug_output` via the Godot MCP to test without leaving the terminal.

Want me to start with Phase 1 (the slime enemy)?
