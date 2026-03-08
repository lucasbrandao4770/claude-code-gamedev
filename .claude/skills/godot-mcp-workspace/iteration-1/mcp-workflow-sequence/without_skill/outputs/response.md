# Creating a Skeleton Enemy Scene with Godot MCP

Here is the full sequence of MCP calls and Claude Code tool calls you need, in order. The MCP can handle scene structure (creating scenes, adding nodes, loading sprites), but it **cannot** write GDScript, attach scripts to nodes, set complex properties like `Vector2`, or instance sub-scenes. Those gaps are filled by Claude Code's Write and Edit tools.

---

## Phase 1: Import Assets

Before the MCP can reference any sprite sheets, Godot needs to import them.

1. **Place your skeleton sprite sheets** (e.g., `skeleton_walk.png`, `skeleton_idle.png`) into your project's asset directory (e.g., `res://assets/enemies/`).

2. **Run headless import** so Godot generates `.import` metadata:

```bash
godot --headless --import
```

This is mandatory. If you skip it, `load_sprite` will fail because Godot won't recognize the new image files.

---

## Phase 2: Build the Scene Tree with MCP

### Step 1 — Create the scene

```
MCP: create_scene
  - scene_name: "skeleton"
  - root_type: "CharacterBody2D"
```

This gives you `skeleton.tscn` with a `CharacterBody2D` root node (the standard base for enemies that move and collide with the world).

### Step 2 — Add child nodes for visuals and physics

```
MCP: add_node
  - scene_path: "res://scenes/skeleton.tscn"   (or wherever create_scene put it)
  - node_name: "AnimatedSprite2D"
  - node_type: "AnimatedSprite2D"
  - parent: "Skeleton"                          (the root node name)
```

```
MCP: add_node
  - scene_path: "res://scenes/skeleton.tscn"
  - node_name: "CollisionShape2D"
  - node_type: "CollisionShape2D"
  - parent: "Skeleton"
```

This `CollisionShape2D` is for the **body** collision (wall/world interaction). You will set its shape manually later via Edit.

### Step 3 — Add the damage hitbox (Area2D + its own CollisionShape2D)

**Critical rule:** Use `Area2D` for damage detection, never body-to-body collision. This is the hitbox/hurtbox pattern.

```
MCP: add_node
  - scene_path: "res://scenes/skeleton.tscn"
  - node_name: "HurtboxArea"
  - node_type: "Area2D"
  - parent: "Skeleton"
```

```
MCP: add_node
  - scene_path: "res://scenes/skeleton.tscn"
  - node_name: "HurtboxShape"
  - node_type: "CollisionShape2D"
  - parent: "Skeleton/HurtboxArea"
```

### Step 4 — (Optional) Add a detection range for chasing

If you want the skeleton to only chase the player when they are within a certain radius:

```
MCP: add_node
  - scene_path: "res://scenes/skeleton.tscn"
  - node_name: "DetectionZone"
  - node_type: "Area2D"
  - parent: "Skeleton"
```

```
MCP: add_node
  - scene_path: "res://scenes/skeleton.tscn"
  - node_name: "DetectionShape"
  - node_type: "CollisionShape2D"
  - parent: "Skeleton/DetectionZone"
```

### Step 5 — Load sprites

```
MCP: load_sprite
  - scene_path: "res://scenes/skeleton.tscn"
  - node_name: "AnimatedSprite2D"
  - sprite_path: "res://assets/enemies/skeleton_walk.png"
  - hframes: 6       (adjust to your sheet's column count)
  - vframes: 4       (adjust to your sheet's row count)
```

Repeat for additional animations if you have separate sheets (idle, attack, death). If your sprite sheets use the CraftPix top-down convention, the row order is: DOWN=0, LEFT=1, RIGHT=2, UP=3.

---

## Phase 3: Write the GDScript (Claude Code Write tool)

The MCP **cannot** create GDScript files. Use the Write tool to create `skeleton.gd`:

```gdscript
extends CharacterBody2D

@export var speed: float = 60.0
@export var chase_range: float = 150.0
@export var damage: int = 1

var player: Node2D = null

func _ready():
    # Find the player in the scene tree
    player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
    if player == null:
        return

    var distance = global_position.distance_to(player.global_position)
    if distance <= chase_range:
        var direction = (player.global_position - global_position).normalized()
        velocity = direction * speed
        _update_animation(direction)
    else:
        velocity = Vector2.ZERO
        $AnimatedSprite2D.stop()

    move_and_slide()

func _update_animation(direction: Vector2):
    # Adapt row selection to your sprite sheet layout
    $AnimatedSprite2D.play()
    if abs(direction.x) > abs(direction.y):
        if direction.x > 0:
            $AnimatedSprite2D.frame = 2 * $AnimatedSprite2D.sprite_frames.get_frame_count("default")  # RIGHT row
        else:
            $AnimatedSprite2D.frame = 1 * $AnimatedSprite2D.sprite_frames.get_frame_count("default")  # LEFT row
    else:
        if direction.y > 0:
            $AnimatedSprite2D.frame = 0  # DOWN row
        else:
            $AnimatedSprite2D.frame = 3 * $AnimatedSprite2D.sprite_frames.get_frame_count("default")  # UP row

func _on_hurtbox_area_area_entered(area):
    if area.is_in_group("player_hurtbox"):
        area.get_parent().take_damage(damage)
```

**Important for contact damage:** The `area_entered` signal only fires once when overlapping begins. For continuous contact damage, also add a periodic check using `get_overlapping_areas()` in `_physics_process` or on a Timer.

---

## Phase 4: Attach the Script and Set Complex Properties (Claude Code Edit tool)

The MCP **cannot** attach scripts or set `Vector2`/`Color` properties. You must edit the `.tscn` file directly.

Use the **Edit tool** on `skeleton.tscn` to:

1. **Attach the script** to the root node by adding `script = ExtResource("X_xxxxx")` (where the ext_resource is declared for `skeleton.gd`).

2. **Set collision shapes** — add `RectangleShape2D` or `CircleShape2D` sub-resources with their `size` or `radius` properties.

3. **Set collision layers and masks** — for example, put the skeleton body on the "enemies" layer and the HurtboxArea on the "enemy_damage" layer, masking the "player_hurtbox" layer.

4. **Connect signals** — wire `HurtboxArea.area_entered` to the script's `_on_hurtbox_area_area_entered` method (or connect in `_ready()` via code).

Example edits you would make in the `.tscn` file:

- Add an `[ext_resource]` entry pointing to `skeleton.gd`
- On the root node's section, add `script = ExtResource("id_of_script")`
- Add `[sub_resource]` entries for the collision shapes with their dimensions
- On each `CollisionShape2D` node, set `shape = SubResource("id_of_shape")`

---

## Phase 5: Instance in the World and Test (MCP + Edit)

The MCP **cannot** instance sub-scenes into other scenes. To place the skeleton in your game world:

1. **Edit tool** on your `game_world.tscn` to add an `[ext_resource]` for `skeleton.tscn` and add an `[node]` entry that instances it, setting its `position` property.

2. **Run and debug** with MCP:

```
MCP: run_project
```

```
MCP: get_debug_output
```

Check for errors, fix them, then:

```
MCP: stop_project
```

Repeat the run/debug/stop cycle until the skeleton behaves correctly.

---

## Summary: Call Sequence at a Glance

| Step | Tool | Call |
|------|------|------|
| 1 | Bash | `godot --headless --import` (after adding sprite files) |
| 2 | MCP | `create_scene` (CharacterBody2D root) |
| 3 | MCP | `add_node` x4-6 (AnimatedSprite2D, CollisionShape2D, HurtboxArea, HurtboxShape, optionally DetectionZone + DetectionShape) |
| 4 | MCP | `load_sprite` (bind sprite sheet to AnimatedSprite2D) |
| 5 | Write | Create `skeleton.gd` with chase AI and damage logic |
| 6 | Edit | Attach script to root node in `.tscn` |
| 7 | Edit | Set collision shapes, layers/masks, and Vector2 properties in `.tscn` |
| 8 | Edit | Instance skeleton into `game_world.tscn` |
| 9 | MCP | `run_project` + `get_debug_output` + `stop_project` (debug loop) |

The key takeaway: **MCP handles scene structure and sprites; Claude Code handles scripts, complex properties, and sub-scene instancing.** Knowing where each tool's boundary is prevents wasted time on calls that silently fail.
