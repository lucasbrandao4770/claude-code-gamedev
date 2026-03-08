---
name: tscn-editor
description: >-
  File format skill for safely editing Godot .tscn and .tres scene/resource files.
  Activate this skill whenever reading, writing, or editing ANY .tscn or .tres file —
  creating scenes from scratch, attaching scripts to nodes, adding sub-resources (collision
  shapes, materials, animations), setting complex properties (Vector2, Color, Rect2,
  Transform2D), instancing sub-scenes, adding signal connections, fixing merge conflicts, or
  patching scenes after MCP operations. Without this skill, .tscn edits risk silent
  corruption — scenes load but behave wrong, or Godot re-saves them differently. Even small
  edits need correct section ordering, ID uniqueness, and reference syntax. If the task
  touches a .tscn or .tres file in any way, use this skill.
---

# .tscn / .tres File Format Skill

Godot scene files (.tscn) and resource files (.tres) are human-readable text, but they have strict formatting rules. Getting them wrong produces silent corruption — the scene loads, but properties are missing, nodes misbehave, or Godot rewrites the file on save. This skill ensures every edit is syntactically correct.

## File Structure — Strict Section Ordering

A .tscn file has exactly five sections, and they MUST appear in this order. Godot's parser expects this sequence — putting nodes before sub-resources, or sub-resources before ext-resources, corrupts the file.

```
[gd_scene format=3 uid="uid://..."]           ← 1. Header (exactly one)

[ext_resource type="..." path="..." id="..."]  ← 2. External resources (zero or more)

[sub_resource type="..." id="..."]             ← 3. Sub-resources (zero or more)
property = value

[node name="..." type="..." parent="..."]      ← 4. Nodes (one or more)
property = value

[connection signal="..." from="..." to="..."]  ← 5. Connections (zero or more)
```

Blank lines between sections are cosmetic — Godot ignores them. Comments use `;` prefix but are removed on save.

## Section 1: Header

```
[gd_scene format=3 uid="uid://cecaux1sm7mo0"]
```

- `format=3` — Godot 4.x format (format=2 is Godot 3.x, never use it)
- `uid` — unique resource identifier; Godot generates this automatically
- `load_steps` — deprecated in Godot 4.6+ ([PR #103352](https://github.com/godotengine/godot/pull/103352), merged Dec 2025). Godot 4.6+ no longer writes it but still parses it if present for backwards compatibility. If writing for Godot 4.5 or earlier, set it to the number of resources in the file (ext_resource + sub_resource count, +1 for the scene itself)

When creating a new .tscn from scratch, you can omit `uid` — Godot assigns one on first save. You can also omit `load_steps` for Godot 4.6+.

Minimal valid header: `[gd_scene format=3]`

## Section 2: External Resources

External resources reference files outside the .tscn — scripts, textures, other scenes, audio, fonts.

```
[ext_resource type="Script" path="res://scripts/player/player.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://assets/sprites/player/idle.png" id="2_tex"]
[ext_resource type="PackedScene" path="res://scenes/enemies/slime.tscn" id="3_enemy"]
```

**Attributes:**
- `type` — Godot class: `Script`, `Texture2D`, `PackedScene`, `AudioStream`, `FontFile`, `Material`, `Shader`, etc.
- `uid` — optional; Godot adds this on save for relocatable references
- `path` — `res://` path to the file (always use forward slashes, never backslashes)
- `id` — string ID, unique among ext_resources (referenced via `ExtResource("id")`)

**ID namespaces are separate:** ext_resource IDs and sub_resource IDs live in different namespaces. An ext_resource and a sub_resource can share the same `id` string without conflict — they're distinguished by `ExtResource()` vs `SubResource()` in references. However, two ext_resources must never share an ID, and two sub_resources must never share an ID.

**ID convention:** Godot uses `"number_randomstring"` format (e.g., `"1_8afob"`, `"2_script"`). You can use any unique string, but following this convention makes diffs cleaner when Godot re-saves.

**Reference syntax in nodes:**
```
script = ExtResource("1_script")
texture = ExtResource("2_tex")
```

## Section 3: Sub-Resources

Sub-resources are resources embedded inside the .tscn — collision shapes, animation data, materials, fonts. They exist only within this file.

```
[sub_resource type="RectangleShape2D" id="RectangleShape2D_body1"]
size = Vector2(10, 10)

[sub_resource type="CircleShape2D" id="CircleShape2D_detect"]
radius = 64.0
```

**Attributes:**
- `type` — resource class: `RectangleShape2D`, `CircleShape2D`, `CapsuleShape2D`, `StandardMaterial3D`, `Animation`, `SpriteFrames`, etc.
- `id` — string ID, unique among sub_resources (convention: `TypeName_randomchars`)

**Reference syntax in nodes:**
```
shape = SubResource("RectangleShape2D_body1")
```

**Ordering rule:** if sub-resource B references sub-resource A, A must be declared first.

## Section 4: Nodes

Nodes form the scene tree. Each node block starts with a heading, followed by zero or more property assignments.

```
[node name="Player" type="CharacterBody2D"]
script = ExtResource("1_script")
collision_layer = 2
collision_mask = 1

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")

[node name="Body" type="CollisionShape2D" parent="."]
position = Vector2(0, 4)
shape = SubResource("RectangleShape2D_body1")

[node name="HurtBox" type="Area2D" parent="."]

[node name="CollisionShape2D" type="CollisionShape2D" parent="HurtBox"]
shape = SubResource("CircleShape2D_hurt1")
```

**Node heading attributes:**
- `name` — node name in the scene tree (required)
- `type` — Godot class name (required for non-instance nodes; omit for instanced scenes)
- `parent` — path from root:
  - Root node: **no parent attribute** (omit entirely)
  - Direct children of root: `parent="."`
  - Deeper nesting: `parent="ParentName"` or `parent="Parent/Child"`
- `instance` — for sub-scene instances: `instance=ExtResource("id")`
- `unique_id` — integer node tracking ID (Godot 4.6+ only). Tracks nodes even if moved or renamed, making refactoring safer. Not present in scenes saved with older Godot versions.
- `groups` — array of group names: `groups=["enemies", "damageable"]`
- `index` — integer controlling node order among siblings (used in inherited scenes)
- `instance_placeholder` — placeholder path for deferred scene instancing (rare)
- `owner` — owner node reference for scene inheritance (rare)

**The root node is the first `[node]` block and must have no `parent` attribute.**

**Properties matching their default values are NOT stored** — Godot omits them on save. If you manually add a property that matches the node type's default (e.g., `visible = true` on a Node2D), Godot silently discards it on next save. This isn't corruption — it's expected behavior. Only set properties that differ from defaults.

**Whitespace is not significant** (except within strings). Extraneous whitespace is removed on save. Comments use `;` prefix but are also discarded on save — don't rely on inline documentation in .tscn files.

## Section 5: Signal Connections

Signal connections appear at the very end of the file.

```
[connection signal="area_entered" from="HurtBox" to="." method="_on_hurt_box_area_entered"]
[connection signal="body_entered" from="DetectionZone" to="." method="_on_detection_zone_body_entered"]
[connection signal="pressed" from="UI/Button" to="." method="_on_button_pressed" binds=[42]]
```

**Attributes:**
- `signal` — signal name on the source node
- `from` — path to the emitting node (relative to scene root)
- `to` — path to the receiving node (usually `"."` for root)
- `method` — callback method name
- `binds` — optional array of extra arguments: `binds=[1, "damage"]`
- `unbinds` — optional integer to remove trailing signal arguments: `unbinds=1`
- `flags` — optional integer for connection flags (rarely needed in hand-edited files)

## Property Serialization

Every property value in a .tscn file follows Godot's serialization format. Getting the syntax wrong causes the property to be silently ignored.

| Type | Syntax | Example |
|------|--------|---------|
| int | bare number | `42` |
| float | number with decimal | `3.14`, `1.0` |
| bool | lowercase | `true`, `false` |
| String | double-quoted | `"hello"` |
| null | keyword | `null` |
| Vector2 | constructor | `Vector2(1.5, 2.5)` |
| Vector2i | constructor | `Vector2i(10, 20)` |
| Vector3 | constructor | `Vector3(1, 2, 3)` |
| Color | constructor (RGBA 0-1) | `Color(1, 0.5, 0, 1)` |
| Rect2 | constructor (x,y,w,h) | `Rect2(0, 0, 100, 50)` |
| Transform2D | 6 floats | `Transform2D(1, 0, 0, 1, 10, 20)` |
| NodePath | constructor | `NodePath("../Player")`, `NodePath("Node:property")` |
| Array | brackets | `[1, 2, "three"]` |
| Dictionary | braces | `{"key": "value"}` |
| PackedInt32Array | typed constructor | `PackedInt32Array(1, 2, 3)` |
| PackedFloat32Array | typed constructor | `PackedFloat32Array(0.5, 1.0)` |
| PackedStringArray | typed constructor | `PackedStringArray("a", "b")` |
| Transform3D | 12 floats | `Transform3D(1,0,0, 0,1,0, 0,0,1, 0,0,0)` |
| Quaternion | constructor | `Quaternion(0, 0, 0, 1)` |
| AABB | constructor | `AABB(0, 0, 0, 1, 1, 1)` |
| Resource ref | ExtResource/SubResource | `ExtResource("1_tex")` |

**Collision layers and masks are integers.** Layer 1 = `1`, Layer 2 = `2`, Layer 1+2 = `3`, Layer 3 = `4` (it's a bitmask: Layer N = `2^(N-1)`). Common values:

```
Layer 1 alone  = 1     Layer 1+2   = 3
Layer 2 alone  = 2     Layer 1+3   = 5
Layer 3 alone  = 4     Layer 2+3   = 6
Layer 4 alone  = 8     Layer 1+2+3 = 7
Layer 5 alone  = 16    Layer 4+5   = 24
```

## Common Edit Patterns

### Attaching a Script to a Scene

Add the script as an ext_resource, then reference it on the root node.

```
[ext_resource type="Script" path="res://scripts/player/player.gd" id="2_script"]

[node name="Player" type="CharacterBody2D"]
script = ExtResource("2_script")
```

Make sure the ext_resource ID is unique and doesn't collide with existing IDs in the file.

### Adding a Collision Shape

Define the shape as a sub_resource, then reference it in a CollisionShape2D node.

```
[sub_resource type="RectangleShape2D" id="RectangleShape2D_body1"]
size = Vector2(12, 12)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(0, 4)
shape = SubResource("RectangleShape2D_body1")
```

Common shape types: `RectangleShape2D` (size), `CircleShape2D` (radius), `CapsuleShape2D` (radius, height), `WorldBoundaryShape2D`, `ConvexPolygonShape2D`, `SegmentShape2D`.

### Instancing a Sub-Scene

Reference the .tscn as a PackedScene ext_resource, then use `instance=` on the node.

```
[ext_resource type="PackedScene" path="res://scenes/enemies/slime.tscn" id="3_enemy"]

[node name="Slime1" parent="Enemies" instance=ExtResource("3_enemy")]
position = Vector2(200, 150)

[node name="Slime2" parent="Enemies" instance=ExtResource("3_enemy")]
position = Vector2(350, 200)
```

Instance nodes inherit everything from the source scene. Properties you set override the source defaults. You do NOT need a `type` attribute — it comes from the instanced scene.

### Setting Complex Properties

These must be set in the .tscn file directly — MCP's `add_node` silently drops them.

```
[node name="Camera2D" type="Camera2D" parent="."]
zoom = Vector2(2, 2)
position_smoothing_enabled = true
position_smoothing_speed = 8.0

[node name="Background" type="ColorRect" parent="."]
color = Color(0.18, 0.545, 0.341, 1)
size = Vector2(800, 600)

[node name="Sprite2D" type="Sprite2D" parent="."]
offset = Vector2(0, -8)
hframes = 12
vframes = 4
frame = 0
```

### Hitbox/Hurtbox Pattern (Area2D)

This pattern prevents the player-pushes-enemy bug. Bodies don't collide with each other — all damage goes through Area2D overlaps.

```
[sub_resource type="RectangleShape2D" id="RectangleShape2D_sword"]
size = Vector2(14, 8)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_hurt"]
size = Vector2(10, 12)

[node name="SwordHitBox" type="Area2D" parent="."]
collision_layer = 8
collision_mask = 0

[node name="CollisionShape2D" type="CollisionShape2D" parent="SwordHitBox"]
shape = SubResource("RectangleShape2D_sword")
disabled = true

[node name="HurtBox" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 16

[node name="CollisionShape2D" type="CollisionShape2D" parent="HurtBox"]
shape = SubResource("RectangleShape2D_hurt")
```

## .tres Resource Files

A .tres file stores a single standalone resource. Same syntax as .tscn but with a different header and no nodes.

```
[gd_resource type="StandardMaterial3D" format=3 uid="uid://..."]

[ext_resource type="Texture2D" path="res://texture.png" id="1_tex"]

[sub_resource type="ShaderMaterial" id="ShaderMaterial_abc"]
shader = ExtResource("1_shader")

[resource]
albedo_color = Color(1, 0.5, 0.25, 1)
metallic = 0.5
```

**Key differences from .tscn:**
- Header: `[gd_resource type="..." ...]` instead of `[gd_scene ...]`
- `type` in header specifies the root resource class
- Single `[resource]` block instead of `[node]` blocks
- No `[connection]` section

## Validation Checklist

Run this checklist after EVERY .tscn/.tres edit. These are the errors that cause silent corruption:

1. **Section ordering**: header → ext_resource → sub_resource → node → connection. Out-of-order sections corrupt the file.

2. **ID uniqueness**: every ext_resource `id` must be unique among ext_resources; every sub_resource `id` must be unique among sub_resources. (The two namespaces are separate — an ext_resource and sub_resource can share the same ID string, but two ext_resources cannot.)

3. **Reference integrity**: every `ExtResource("id")` and `SubResource("id")` must point to an existing block. Dangling references cause null properties at runtime.

4. **Path validity**: every ext_resource `path` should point to a file that exists in the project. Use `res://` prefix with forward slashes.

5. **Root node has no parent**: the first `[node]` block must NOT have a `parent` attribute. All other nodes must have one.

6. **Parent paths are correct**: `"."` for root's children, `"ParentName"` for deeper nodes. Wrong paths create orphan nodes or crash on load.

7. **No GDScript in scene files**: never use `var`, `const`, `func`, `preload()`, `load()`, `class_name`, `extends` in .tscn/.tres files. These are resource files, not scripts.

8. **Property syntax matches type**: `Vector2(x, y)` not `(x, y)`, `Color(r, g, b, a)` not `#RRGGBB`, `true` not `True`.

## Silent Corruption Pitfalls

These are real bugs from development sessions — each was caused by an incorrect .tscn edit that loaded without errors but behaved wrong:

- **Wrong `parent` path** → node appears in scene tree at wrong location, scripts can't find child nodes via `$NodeName`
- **Missing sub_resource block** → `shape = SubResource("id")` resolves to null, collision silently doesn't work
- **Duplicate ext_resource ID** → Godot binds the wrong resource to one of the references
- **Property on wrong node type** → Godot ignores unknown properties silently (e.g., `radius` on a Node2D does nothing)
- **ext_resource after sub_resource** → parser may skip or misinterpret later blocks
- **`preload()` in .tscn** → parse error; use `ExtResource()` for .tscn, save `preload()` for .gd scripts
