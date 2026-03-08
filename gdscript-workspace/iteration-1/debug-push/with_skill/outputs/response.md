# Diagnosis: Slime Pushes Player Instead of Dealing Damage

## The Problem

Both your player and slime are `CharacterBody2D` nodes. When `move_and_slide()` runs on the slime during its CHASE state, Godot's physics engine detects the body-to-body collision between the two `CollisionShape2D` shapes and resolves the overlap by pushing the player away. This is the default `CharacterBody2D` behavior -- it treats all colliding bodies as solid obstacles and slides them apart.

The slime **does** have an `Area2D` contact hitbox (`ContactHitBox`) for damage, but the body collision fires *before* the area overlap has a chance to matter. The physics engine resolves the push every frame, so the player gets shoved across the map continuously while the slime chases.

## Root Cause

The slime's `CollisionShape2D` (body) has its collision mask set to include the player's layer:

```gdscript
# Slime body: layer 3 (enemies), mask 1 (world)
collision_layer = 4   # bit 3
collision_mask = 1     # bit 1 (world only)
```

And the player's body:

```gdscript
# Player body: layer 2 (player), mask 1 (world)
collision_layer = 2   # bit 2
collision_mask = 1     # bit 1 (world only)
```

At first glance, the masks look correct -- neither body masks the other's layer. **However**, `CharacterBody2D.move_and_slide()` has a subtle behavior: it still resolves collisions with bodies on its **own** layer if the *other* body's mask includes your layer. In practice, two `CharacterBody2D` nodes with overlapping shapes will push each other even if neither explicitly masks the other, because `move_and_slide()` uses the physics server's collision detection which is bidirectional -- if body A is on layer 2 and body B's mask includes layer 2, body A's `move_and_slide()` will detect body B as a collision partner.

But looking more carefully at your setup: the player is on layer 2 (bit value `2`) and the slime masks bit 1 only (value `1`), and the slime is on layer 3 (bit value `4`) and the player masks bit 1 only (value `1`). So neither should detect the other's body... unless there is a discrepancy between the script values and what the scene file actually has.

**The real issue is simpler than it seems.** Regardless of the specific layer/mask debugging, the fundamental architectural problem is:

> You should **never** rely on `CharacterBody2D` body collisions between players and enemies. Even if layers are "correctly" configured, edge cases in `move_and_slide()` can still cause pushing. The correct pattern is to use `Area2D` nodes exclusively for damage detection and ensure the bodies cannot physically interact at all.

## The Fix

There are two parts to a robust fix:

### Part 1: Guarantee bodies cannot collide

Make absolutely sure the slime's body does not mask the player's layer and vice versa. The safest approach is to explicitly set these in `_ready()` and double-check the bitmask values:

```gdscript
# In slime.gd _setup_collision_layers():
# Body: layer 3 (enemies), mask 1 (world) ONLY
# Layer 3 = bit 2^(3-1) = 4, Mask layer 1 = bit 2^(1-1) = 1
collision_layer = 4
collision_mask = 1   # world only, NOT player (layer 2 = bit 2)
```

```gdscript
# In player.gd _setup_collision_layers():
# Body: layer 2 (player), mask 1 (world) ONLY
# Layer 2 = bit 2^(2-1) = 2, Mask layer 1 = bit 2^(1-1) = 1
collision_layer = 2
collision_mask = 1   # world only, NOT enemies (layer 3 = bit 4)
```

This is what your code already says -- but if the `.tscn` scene files have different values set in their resource properties, those will **override** the script values because `_setup_collision_layers()` runs in `_ready()`, which fires *after* the scene's exported properties are applied. Since both write to the same property, the script wins. But verify that no other code path modifies these.

### Part 2: Confirm Area2D damage is working

Your existing `ContactHitBox` (Area2D) on the slime and `HurtBox` (Area2D) on the player already implement the correct hitbox/hurtbox pattern:

- Slime `ContactHitBox`: layer 5 (bit 16), mask 0, monitorable = true, in group "enemy_hitbox"
- Player `HurtBox`: layer 0, mask 5 (bit 16), monitoring = true

And the player has both:
1. `area_entered` signal connection for instant detection
2. `_check_overlapping_damage()` polling for continuous contact damage

This is the correct dual-detection pattern from the skill guide.

### If Bodies Are Still Pushing (Nuclear Option)

If after verifying layers the push still happens, the definitive fix is to **disable the slime's `CharacterBody2D` collision with the player entirely** by removing the player layer from the slime's mask and the enemy layer from the player's mask. Since your code already does this, and the pushing is still occurring, there is likely a mismatch in the `.tscn` file. You have two options:

**Option A: Fix the .tscn file**

Open the slime `.tscn` and player `.tscn` files and ensure the `collision_layer` and `collision_mask` properties are not set (let the script handle it), or set them correctly:

```
; In slime.tscn, on the root CharacterBody2D:
collision_layer = 4
collision_mask = 1

; In player.tscn, on the root CharacterBody2D:
collision_layer = 2
collision_mask = 1
```

**Option B: Use `set_collision_mask_value()` for clarity**

Replace the bitfield math with Godot's named-bit API so there is zero ambiguity:

```gdscript
# slime.gd - _setup_collision_layers()
func _setup_collision_layers() -> void:
	# Body: on "Enemies" layer (3), collides with "World" (1) ONLY
	set_collision_layer_value(1, false)
	set_collision_layer_value(2, false)
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, false)  # explicitly exclude player
	set_collision_mask_value(3, false)

	# ... rest of Area2D setup unchanged
```

```gdscript
# player.gd - _setup_collision_layers()
func _setup_collision_layers() -> void:
	# Body: on "Player" layer (2), collides with "World" (1) ONLY
	set_collision_layer_value(1, false)
	set_collision_layer_value(2, true)
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, false)
	set_collision_mask_value(3, false)  # explicitly exclude enemies

	# ... rest of Area2D setup unchanged
```

Using `set_collision_layer_value(layer_number, bool)` is clearer because you use 1-indexed layer numbers (matching the editor) instead of computing bitmasks manually.

## Complete Fixed `_setup_collision_layers()` for Both Scripts

### slime.gd

```gdscript
func _setup_collision_layers() -> void:
	# Body: layer 3 (enemies), collides with layer 1 (world) ONLY
	# Explicitly exclude player layer to prevent pushing
	set_collision_layer_value(1, false)
	set_collision_layer_value(2, false)
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, false)
	set_collision_mask_value(3, false)

	# Detection zone: detects bodies on layer 2 (player)
	detection_zone.collision_layer = 0
	detection_zone.collision_mask = 2
	detection_zone.monitoring = true
	detection_zone.body_entered.connect(_on_detection_body_entered)
	detection_zone.body_exited.connect(_on_detection_body_exited)

	# Contact hitbox: layer 5 (enemy_hitbox), does not monitor -- is monitored by player
	contact_hitbox.collision_layer = 16
	contact_hitbox.collision_mask = 0
	contact_hitbox.monitoring = false
	contact_hitbox.monitorable = true
	contact_hitbox.add_to_group("enemy_hitbox")

	# Hurtbox: monitors layer 4 (player_hitbox = bit 8)
	hurt_box.collision_layer = 0
	hurt_box.collision_mask = 8
	hurt_box.monitoring = true
	hurt_box.monitorable = false
	hurt_box.area_entered.connect(_on_hurtbox_area_entered)
```

### player.gd

```gdscript
func _setup_collision_layers() -> void:
	# Body: layer 2 (player), collides with layer 1 (world) ONLY
	# Explicitly exclude enemy layer to prevent pushing
	set_collision_layer_value(1, false)
	set_collision_layer_value(2, true)
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, false)
	set_collision_mask_value(3, false)

	# Sword hitbox: layer 4 (player_hitbox = bit 8)
	sword_hitbox.collision_layer = 8
	sword_hitbox.collision_mask = 0
	sword_hitbox.monitoring = false
	sword_hitbox.monitorable = true

	# Hurtbox: monitors layer 5 (enemy_hitbox = bit 16)
	hurt_box.collision_layer = 0
	hurt_box.collision_mask = 16
	hurt_box.monitoring = true
	hurt_box.monitorable = false
	hurt_box.area_entered.connect(_on_hurtbox_area_entered)
```

## Summary

| Aspect | Wrong Approach | Correct Approach |
|--------|---------------|-----------------|
| Damage detection | Body-to-body collision (`CharacterBody2D` vs `CharacterBody2D`) | `Area2D` hitbox/hurtbox pattern |
| Body collision layers | Player and enemy bodies can "see" each other | Bodies only collide with world/terrain (layer 1) |
| Contact damage | Relying on physics push as implicit "hit" | `area_entered` signal + periodic `get_overlapping_areas()` polling |
| Layer configuration | Raw bitmask math (`collision_mask = 1`) | `set_collision_mask_value(layer, bool)` for clarity |

The key rule from the GDScript skill guide: **Use `Area2D` for damage, never body-to-body collision between player and enemies.** The `ContactHitBox` and `HurtBox` Area2D nodes you already have are the correct architecture -- the fix is ensuring the `CharacterBody2D` bodies themselves are invisible to each other so `move_and_slide()` never pushes them apart.
