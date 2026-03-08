# Creating a Skeleton Enemy Scene with Godot MCP

Here is the complete sequence of MCP calls and supporting tool operations you need, in the exact order they should be executed. I am breaking this into phases so you can see why each step matters.

---

## Phase 1: Asset Preparation (Before Any MCP Calls)

Before touching MCP, get your skeleton sprite sheets into the project:

1. **Place your skeleton sprite files** into the project's asset folder (e.g., `assets/sprites/enemies/skeleton/`).

2. **Run the headless import** via Bash:
   ```bash
   godot --headless --path <your_project_path> --import
   ```
   This is the single most critical step. If you skip it, `load_sprite` will fail with "No loader found for resource" because Godot does not recognize raw files on disk as resources until they have been imported. Every new asset file requires this.

---

## Phase 2: Build the Scene Tree with MCP

Now use the MCP tools to create the scene and add nodes. The skeleton needs a `CharacterBody2D` root (for physics movement and `move_and_slide()`), plus child nodes for visuals, collision, damage dealing, damage receiving, and player detection.

### Step 1 -- Create the scene

```
create_scene(
  projectPath = "<your_project_path>",
  scenePath = "scenes/enemies/skeleton.tscn",
  rootNodeType = "CharacterBody2D"
)
```

### Step 2 -- Add the Sprite2D

```
add_node(
  projectPath = "<your_project_path>",
  scenePath = "scenes/enemies/skeleton.tscn",
  nodeType = "Sprite2D",
  nodeName = "Sprite2D",
  parentNodePath = "root"
)
```

### Step 3 -- Add the body CollisionShape2D

```
add_node(
  projectPath = "<your_project_path>",
  scenePath = "scenes/enemies/skeleton.tscn",
  nodeType = "CollisionShape2D",
  nodeName = "CollisionShape2D",
  parentNodePath = "root"
)
```

**Important:** MCP cannot set the `shape` property (it is a sub-resource, not a simple type). The shape will be defined later by editing the .tscn file directly or by assigning it in `_ready()`.

### Step 4 -- Add the HurtBox (receives damage from player's sword)

```
add_node(
  projectPath = "<your_project_path>",
  scenePath = "scenes/enemies/skeleton.tscn",
  nodeType = "Area2D",
  nodeName = "HurtBox",
  parentNodePath = "root"
)
```

### Step 5 -- Add CollisionShape2D inside HurtBox

```
add_node(
  projectPath = "<your_project_path>",
  scenePath = "scenes/enemies/skeleton.tscn",
  nodeType = "CollisionShape2D",
  nodeName = "CollisionShape2D",
  parentNodePath = "root/HurtBox"
)
```

### Step 6 -- Add the ContactHitBox (deals contact damage to the player)

```
add_node(
  projectPath = "<your_project_path>",
  scenePath = "scenes/enemies/skeleton.tscn",
  nodeType = "Area2D",
  nodeName = "ContactHitBox",
  parentNodePath = "root"
)
```

### Step 7 -- Add CollisionShape2D inside ContactHitBox

```
add_node(
  projectPath = "<your_project_path>",
  scenePath = "scenes/enemies/skeleton.tscn",
  nodeType = "CollisionShape2D",
  nodeName = "CollisionShape2D",
  parentNodePath = "root/ContactHitBox"
)
```

### Step 8 -- Add the DetectionZone (detects the player for chase behavior)

```
add_node(
  projectPath = "<your_project_path>",
  scenePath = "scenes/enemies/skeleton.tscn",
  nodeType = "Area2D",
  nodeName = "DetectionZone",
  parentNodePath = "root"
)
```

### Step 9 -- Add CollisionShape2D inside DetectionZone

```
add_node(
  projectPath = "<your_project_path>",
  scenePath = "scenes/enemies/skeleton.tscn",
  nodeType = "CollisionShape2D",
  nodeName = "CollisionShape2D",
  parentNodePath = "root/DetectionZone"
)
```

### Step 10 -- Load the sprite texture

```
load_sprite(
  projectPath = "<your_project_path>",
  scenePath = "scenes/enemies/skeleton.tscn",
  nodePath = "root/Sprite2D",
  texturePath = "res://assets/sprites/enemies/skeleton/skeleton_idle.png"
)
```

This only works because you ran `godot --headless --import` in Phase 1. If you added the sprite file after that import step, you need to run the import again before this call.

---

## Phase 3: What MCP Cannot Do (Use Write and Edit Tools)

MCP has built the node tree and assigned the sprite, but several critical pieces are beyond its capabilities. You need Claude Code's Write and Edit tools for these:

### A. Write the GDScript (`scripts/enemies/skeleton.gd`)

MCP cannot create GDScript files. Use the **Write tool** to create the script with:
- Chase AI: use the `DetectionZone`'s `body_entered`/`body_exited` signals to track the player, then move toward them in `_physics_process()` using `move_and_slide()`
- Contact damage: add the `ContactHitBox` to the `"enemy_hitbox"` group so the player's hurtbox can detect it
- Damage reception: connect `HurtBox.area_entered` to a `take_damage()` function
- Collision layers set in `_ready()`: body on layer 3 (value 4), mask layer 1 (value 1); DetectionZone masks layer 2 (player); ContactHitBox on layer 5 (value 16); HurtBox masks layer 4 (value 8)

### B. Edit the .tscn to attach the script and define collision shapes

Use the **Edit tool** to patch `skeleton.tscn`. You need to add:

1. An `[ext_resource]` entry for the script:
   ```
   [ext_resource type="Script" path="res://scripts/enemies/skeleton.gd" id="2_script"]
   ```

2. `[sub_resource]` blocks for each collision shape:
   ```
   [sub_resource type="CircleShape2D" id="body_shape"]
   radius = 6.0

   [sub_resource type="CircleShape2D" id="hurt_shape"]
   radius = 7.0

   [sub_resource type="CircleShape2D" id="contact_shape"]
   radius = 7.0

   [sub_resource type="CircleShape2D" id="detect_shape"]
   radius = 80.0
   ```

3. Property assignments on the nodes:
   - Root node: `script = ExtResource("2_script")`
   - Each `CollisionShape2D`: `shape = SubResource("<id>")`
   - Body collision position: `position = Vector2(0, 4)` (MCP silently drops Vector2 values, so this must be in the .tscn)

### C. Set collision layers

You can either set these in the .tscn file or in `_ready()` in the script. Setting them in `_ready()` is often simpler because MCP can set integer properties but cannot set sub-resources. The existing slime in this project uses `_ready()` for all collision layer configuration, which is a proven pattern.

---

## Phase 4: Debug Loop with MCP

Once the script and .tscn edits are in place, use the MCP debug loop:

### Step 11 -- Run the project

```
run_project(
  projectPath = "<your_project_path>"
)
```

### Step 12 -- Check for errors

```
get_debug_output()
```

This returns `{output: [...], errors: [...]}`. Look at the `errors` array for script errors, missing resources, or collision issues.

### Step 13 -- Stop the project

```
stop_project()
```

### Step 14 -- Fix and repeat

Edit your script or .tscn based on the errors, then go back to Step 11. This run/check/stop/fix cycle is the core MCP debug workflow.

---

## Summary: Complete Call Sequence

| Order | Tool | Call | Purpose |
|-------|------|------|---------|
| 0 | Bash | `godot --headless --path <project> --import` | Import skeleton sprite assets |
| 1 | MCP | `create_scene(..., rootNodeType="CharacterBody2D")` | Create skeleton.tscn |
| 2 | MCP | `add_node(nodeType="Sprite2D", ...)` | Visual representation |
| 3 | MCP | `add_node(nodeType="CollisionShape2D", parent="root")` | Physics body shape |
| 4 | MCP | `add_node(nodeType="Area2D", nodeName="HurtBox")` | Receives sword damage |
| 5 | MCP | `add_node(nodeType="CollisionShape2D", parent="root/HurtBox")` | HurtBox shape |
| 6 | MCP | `add_node(nodeType="Area2D", nodeName="ContactHitBox")` | Deals contact damage |
| 7 | MCP | `add_node(nodeType="CollisionShape2D", parent="root/ContactHitBox")` | ContactHitBox shape |
| 8 | MCP | `add_node(nodeType="Area2D", nodeName="DetectionZone")` | Player detection for chase AI |
| 9 | MCP | `add_node(nodeType="CollisionShape2D", parent="root/DetectionZone")` | DetectionZone shape |
| 10 | MCP | `load_sprite(...)` | Assign skeleton texture |
| 11 | Write | Create `skeleton.gd` | AI, damage, collision layers |
| 12 | Edit | Patch `skeleton.tscn` | Attach script, add sub-resources, set Vector2 properties |
| 13 | MCP | `run_project(...)` | Test in-engine |
| 14 | MCP | `get_debug_output()` | Read errors |
| 15 | MCP | `stop_project()` | Clean up |
| 16 | -- | Fix and repeat from 13 | Iterate until working |

---

## Key Gotchas to Watch For

- **Never call `load_sprite` before `godot --headless --import`** on new assets. It will fail silently or with a cryptic "no loader found" error.
- **MCP silently drops Vector2, Color, and sub-resource properties** passed via `add_node`. Always set these in the .tscn file or in `_ready()`.
- **MCP cannot attach scripts to nodes.** You must edit the .tscn to add the `[ext_resource]` and `script = ExtResource(...)` lines.
- **Use Area2D for all damage interactions**, not body-to-body collision. Body-to-body causes pushing behavior instead of damage.
- **Use both `area_entered` signal AND periodic `get_overlapping_areas()` checks** for contact damage. The signal only fires once on initial overlap, so sustained contact needs the periodic check.
- **Do not use `update_project_uids`** -- it is broken (double-prefixes paths with `res://`).
