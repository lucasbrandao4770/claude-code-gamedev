Great -- you already have the hardest part done (a moving player). Here is the plan for adding the slime enemy, sword attack, and combat system. I will break it into concrete steps following the build order: **Enemy first, then Player combat, then the system that connects them.**

---

## Before We Start: Collision Layer Design

Combat requires a clear collision layer plan. Confusion between layer numbers and bitmask values is a common bug source, so let's define these up front:

| Layer # | Bitmask Value | Name | Used By |
|---------|--------------|------|---------|
| 1 | 1 | Walls/Environment | TileMap, boundaries |
| 2 | 2 | Player Body | Player CharacterBody2D |
| 3 | 4 | Enemy Body | Slime CharacterBody2D |
| 4 | 8 | Player Hitbox | Sword Area2D (damages enemies) |
| 5 | 16 | Enemy Hurtbox | Slime's hurtbox Area2D (detects player attacks) |
| 6 | 32 | Enemy Hitbox | Slime's contact damage Area2D |
| 7 | 64 | Player Hurtbox | Player's hurtbox Area2D (detects enemy attacks) |

Key wiring:
- Player body: layer=2, mask=1 (collides with walls)
- Enemy body: layer=4, mask=1 (collides with walls, NOT with player body -- avoids push-around bugs)
- Sword hitbox (Area2D): layer=8, mask=0 (passive, emits nothing)
- Enemy hurtbox (Area2D): layer=0, mask=8 (detects player sword)
- Enemy contact hitbox (Area2D): layer=32, mask=0 (passive)
- Player hurtbox (Area2D): layer=0, mask=32 (detects enemy contact)

**Critical rule:** Never use body-to-body collision for damage. The hitbox/hurtbox pattern with Area2D nodes keeps physics and damage logic cleanly separated.

---

## Step 1: Slime Enemy Scene

**Scene structure:**

```
Slime (CharacterBody2D)
+-- Sprite2D
+-- CollisionShape2D          # physics body (layer 3, mask 1)
+-- Hurtbox (Area2D)          # detects sword hits (layer 0, mask 8)
|   +-- CollisionShape2D
+-- Hitbox (Area2D)           # deals contact damage (layer 32, mask 0)
    +-- CollisionShape2D
```

**Script (`slime.gd`) behavior:**
- **State machine:** `enum State { IDLE, CHASE, HURT, DEAD }`
- **IDLE:** Stand still, check distance to player each physics frame
- **CHASE:** When player is within detection range (~120px), move toward player at chase speed (~60 px/s, slower than player)
- **HURT:** Brief knockback in opposite direction, then return to CHASE
- **DEAD:** Play death effect, `queue_free()`
- **Stats:** HP = 3, contact damage = 1, detection range = 120px
- **Contact damage:** Use `area_entered` on the player's hurtbox AND periodic `get_overlapping_areas()` polling (area_entered fires only once per overlap, so without polling, standing on a slime only hurts once)

**Build and test before moving on.** Run the project, confirm the slime chases the player when close and stops when far. No combat yet -- just AI movement.

---

## Step 2: Sword Attack for the Player

**Add to the player scene:**

```
Player (CharacterBody2D)       # existing
+-- Sprite2D                   # existing
+-- CollisionShape2D           # existing
+-- SwordHitbox (Area2D)       # NEW -- layer 8, mask 0
|   +-- CollisionShape2D       # sword-sized rectangle, offset in front of player
+-- Hurtbox (Area2D)           # NEW -- layer 0, mask 32
    +-- CollisionShape2D       # same size as body collision
```

**Script changes to `player.gd`:**
- Add states: `enum State { IDLE, WALK, ATTACK, HURT, DEAD }`
- **Attack input:** On key press (e.g., `ui_accept` or a custom `attack` action), enter ATTACK state
- **During ATTACK:** Disable movement, enable the SwordHitbox collision shape (disabled by default), position it in the direction the player faces, hold for ~0.3s, then disable and return to IDLE
- **Sword positioning:** Offset the SwordHitbox based on `last_direction` -- e.g., facing right = offset `Vector2(24, 0)`, facing up = offset `Vector2(0, -24)`
- **Stats:** Attack damage = 1, attack cooldown = 0.4s

**Build and test.** Run the project, press attack, confirm the sword hitbox appears in the right direction. No damage dealing yet -- just the attack action working.

---

## Step 3: Combat System (Connecting Damage)

Now wire up the damage signals between the existing pieces.

### Slime Takes Damage (from sword)

In `slime.gd`:
- Connect `Hurtbox.area_entered` signal
- When triggered, check if the area is the player's SwordHitbox
- Call `take_damage(amount, attacker_position)` -- reduces HP, enters HURT state, applies knockback away from attacker
- Add invincibility window (~0.5s) to prevent multi-hit from one swing
- When HP reaches 0, enter DEAD state

### Player Takes Damage (from slime contact)

In `player.gd`:
- Connect `Hurtbox.area_entered` signal
- Additionally, in `_physics_process`, poll `Hurtbox.get_overlapping_areas()` to catch ongoing contact (the `area_entered` signal only fires once per overlap start)
- Call `take_damage(amount, attacker_position)` -- reduces HP, enters HURT state, brief stun (~0.3s), invincibility for longer (~1.0s) with sprite blink effect
- **Keep stun short, invincibility long.** If stun matches invincibility, the player can never escape and dies 100% of the time against multiple enemies
- When HP reaches 0, enter DEAD state (respawn or game over -- your call)

### Player Health

- Player HP = 6 (representing 3 hearts at 2 HP each, common Zelda pattern)
- Emit a `health_changed(current, maximum)` signal for future HUD integration

### Damage Flow Summary

```
Player presses attack
  -> SwordHitbox enabled for 0.3s
  -> Slime Hurtbox detects overlap (area_entered)
  -> slime.take_damage(1, player.position)
  -> Slime HP -= 1, knockback, invincibility 0.5s
  -> If HP <= 0: Slime dies

Slime chases and touches player
  -> Player Hurtbox detects overlap (area_entered + polling)
  -> player.take_damage(1, slime.position)
  -> Player HP -= 1, brief stun 0.3s, invincibility 1.0s, sprite blink
  -> If HP <= 0: Player dies
```

**Build and test.** This is the critical moment. Run the project, attack a slime, confirm it takes damage and dies after 3 hits. Walk into a slime, confirm the player takes damage with proper invincibility. Playtest for feel -- does combat feel responsive? Is the detection range right? Tune `@export` values as needed.

---

## Build Order Summary

| Step | What to Build | What to Test | Done When |
|------|--------------|--------------|-----------|
| 1 | Slime scene + chase AI | Slime follows player when close, stops when far | AI movement works |
| 2 | Sword hitbox + attack state | Press attack, hitbox appears in facing direction | Attack animation/state works |
| 3 | Wire damage both ways | Sword kills slime in 3 hits; slime hurts player on contact | Both can take and deal damage |

Each step gets tested in isolation before moving to the next. This prevents cascading bugs -- if step 3 fails, you know steps 1 and 2 work and the bug is in the wiring.

---

## After Combat Works (Polish)

Once the core combat loop feels good:

- **HUD** with hearts display (CanvasLayer so it stays on screen)
- **Audio** -- sword swing SFX, slime hit/death SFX, player hurt SFX (even one sound per action makes a massive difference)
- **Juice** -- knockback on hit, sprite blink during invincibility, brief screen shake on player damage
- **Spawn system** -- multiple slimes in the game world

But none of that matters until the core loop of "chase + attack + damage" feels right. Want me to start building step 1?
