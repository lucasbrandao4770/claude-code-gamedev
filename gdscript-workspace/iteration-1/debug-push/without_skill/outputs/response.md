# Fixing Slime Pushing Player Instead of Dealing Damage

## Diagnosis

When two `CharacterBody2D` nodes collide, Godot's physics engine resolves the collision by **pushing them apart**. This is the default behavior of `move_and_slide()` — it treats other `CharacterBody2D` nodes as solid obstacles and slides along them, which results in the "pushing" effect you're seeing.

The core problem: **you're relying on body-to-body collision for damage, but `CharacterBody2D` collisions are designed for physics separation, not gameplay interactions like damage.**

## The Fix: Hitbox/Hurtbox Pattern with Area2D

The standard solution in Godot is the **Hitbox/Hurtbox pattern**:

1. **Keep** the slime's `CollisionShape2D` on the `CharacterBody2D` for wall/environment collisions
2. **Add** an `Area2D` child node to the slime as a "hitbox" (the thing that deals damage)
3. **Add** an `Area2D` child node to the player as a "hurtbox" (the thing that receives damage)
4. **Use collision layers** so the slime's body doesn't physically push the player

### Step 1: Fix Collision Layers to Prevent Pushing

Set up collision layers so the slime and player bodies don't interact physically:

| Node | Collision Layer | Collision Mask |
|------|----------------|----------------|
| Player (CharacterBody2D) | Layer 1 (Player) | Layer 3 (Environment) |
| Slime (CharacterBody2D) | Layer 2 (Enemy) | Layer 3 (Environment) |
| Player Hurtbox (Area2D) | Layer 4 (PlayerHurtbox) | Layer 5 (EnemyHitbox) |
| Slime Hitbox (Area2D) | Layer 5 (EnemyHitbox) | Layer 4 (PlayerHurtbox) |

By removing each other from their collision masks, the `CharacterBody2D` nodes will pass through each other — no more pushing.

In the Godot editor:
- Select the **Player** `CharacterBody2D` → Inspector → Collision → set Layer to 1, Mask to 3
- Select the **Slime** `CharacterBody2D` → Inspector → Collision → set Layer to 2, Mask to 3

Or in code (in each node's `_ready()` function):

```gdscript
# player.gd — _ready()
collision_layer = 1   # Layer 1: Player body
collision_mask = 4     # Layer 3: Environment only (bit value 4 = layer 3)
```

```gdscript
# slime.gd — _ready()
collision_layer = 2   # Layer 2: Enemy body
collision_mask = 4     # Layer 3: Environment only (bit value 4 = layer 3)
```

> **Note on bit values:** `collision_layer` and `collision_mask` use bitmasks. Layer 1 = `1`, Layer 2 = `2`, Layer 3 = `4`, Layer 4 = `8`, Layer 5 = `16`. To combine layers, add the values (e.g., Layer 1 + Layer 3 = `1 + 4 = 5`).

### Step 2: Add a Hurtbox to the Player

Add an `Area2D` child to the player scene:

```
Player (CharacterBody2D)
├── CollisionShape2D          # existing — for environment physics
├── Sprite2D / AnimatedSprite2D
└── Hurtbox (Area2D)          # NEW — receives damage
    └── CollisionShape2D      # same size or slightly smaller than body
```

Configure the Hurtbox's collision:
- **Layer:** 8 (Layer 4 — PlayerHurtbox)
- **Mask:** 16 (Layer 5 — EnemyHitbox)

### Step 3: Add a Hitbox to the Slime

Add an `Area2D` child to the slime scene:

```
Slime (CharacterBody2D)
├── CollisionShape2D          # existing — for environment physics
├── Sprite2D / AnimatedSprite2D
└── Hitbox (Area2D)           # NEW — deals damage
    └── CollisionShape2D      # same size or slightly larger than body
```

Configure the Hitbox's collision:
- **Layer:** 16 (Layer 5 — EnemyHitbox)
- **Mask:** 8 (Layer 4 — PlayerHurtbox)

### Step 4: Connect the Damage Signal

In your **player script**, connect the hurtbox signal to handle incoming damage:

```gdscript
# player.gd

var max_hp: int = 5
var current_hp: int = 5
var invincible: bool = false
var invincible_timer: float = 0.0
var invincible_duration: float = 1.0  # seconds of invincibility after hit

func _ready() -> void:
    # Connect the hurtbox signal
    $Hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _process(delta: float) -> void:
    # Handle invincibility timer
    if invincible:
        invincible_timer -= delta
        if invincible_timer <= 0.0:
            invincible = false
            modulate.a = 1.0  # restore full opacity

func _on_hurtbox_area_entered(area: Area2D) -> void:
    if invincible:
        return
    # Check if the area belongs to an enemy
    var damage := 1
    if area.has_method("get_damage"):
        damage = area.get_damage()
    take_damage(damage)

func take_damage(amount: int) -> void:
    current_hp -= amount
    current_hp = max(current_hp, 0)
    # Start invincibility frames
    invincible = true
    invincible_timer = invincible_duration
    modulate.a = 0.5  # visual feedback: semi-transparent
    # Emit signal or update HUD
    print("Player took %d damage! HP: %d/%d" % [amount, current_hp, max_hp])
    if current_hp <= 0:
        die()

func die() -> void:
    print("Player died!")
    # Handle death (reload scene, show game over, etc.)
    get_tree().reload_current_scene()
```

### Step 5: (Optional) Add Damage Info to the Slime Hitbox

In your **slime script**, you can expose a damage value:

```gdscript
# slime.gd

var damage: int = 1

func _ready() -> void:
    # The Hitbox Area2D can reference this script for damage
    $Hitbox.set_meta("damage", damage)
```

Or add a small script to the Hitbox `Area2D` node itself:

```gdscript
# slime_hitbox.gd (attached to the Hitbox Area2D)
extends Area2D

func get_damage() -> int:
    return get_parent().damage if get_parent().has("damage") else 1
```

### Step 6: Handle Contact Damage Continuously

**Important caveat:** `area_entered` only fires **once** when two areas first overlap. If the slime stays on top of the player, it won't fire again. To deal continuous contact damage, add a periodic check:

```gdscript
# player.gd — add to _process() or use a Timer

var contact_damage_interval: float = 0.5  # damage every 0.5 seconds
var contact_damage_timer: float = 0.0

func _process(delta: float) -> void:
    # ... existing invincibility logic ...

    # Periodic contact damage check
    if not invincible:
        contact_damage_timer -= delta
        if contact_damage_timer <= 0.0:
            contact_damage_timer = contact_damage_interval
            var overlapping_areas := $Hurtbox.get_overlapping_areas()
            for area in overlapping_areas:
                if area.is_in_group("enemy_hitbox"):  # add slime Hitbox to this group
                    take_damage(1)
                    break  # only take damage once per tick
```

## Summary

| Problem | Solution |
|---------|----------|
| Slime body pushes player body | Remove player from slime's collision mask (and vice versa) |
| No damage on contact | Add Area2D hitbox to slime + Area2D hurtbox to player |
| `area_entered` only fires once | Use periodic `get_overlapping_areas()` for sustained contact |
| Player dies instantly | Add invincibility frames after taking damage |

The key insight is: **`CharacterBody2D` collision is for physics (sliding, blocking, pushing). `Area2D` collision is for gameplay logic (damage, pickups, triggers).** Always use the hitbox/hurtbox pattern for combat interactions in Godot.
