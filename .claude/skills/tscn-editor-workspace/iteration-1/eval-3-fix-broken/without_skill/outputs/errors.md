# Errors Found in Enemy .tscn File

## Error 1: Missing `load_steps` in scene header

- **Line:** `[gd_scene format=3]`
- **Problem:** The `[gd_scene]` header must include `load_steps=N` where N equals the total number of `ext_resource` + `sub_resource` entries plus 1.
- **Fix:** Change to `[gd_scene load_steps=4 format=3]` (1 ext_resource for texture + 1 ext_resource for script + 1 sub_resource + 1 = 4).

## Error 2: `preload()` used for script in .tscn file

- **Line:** `script = preload("res://scripts/enemy.gd")`
- **Problem:** `.tscn` files must never use `preload()`. Scripts must be declared as `[ext_resource]` entries and referenced via `ExtResource("id")`.
- **Fix:** Add `[ext_resource type="Script" path="res://scripts/enemy.gd" id="2_script"]` and change the line to `script = ExtResource("2_script")`.

## Error 3: Wrong syntax for `position` property

- **Line:** `position = (100, 200)`
- **Problem:** Godot .tscn files use `Vector2(100, 200)` for 2D vector properties, not Python-style tuple syntax `(100, 200)`.
- **Fix:** Change to `position = Vector2(100, 200)`.

## Error 4: `[ext_resource]` declared after `[node]`

- **Line:** `[ext_resource type="Texture2D" path="res://sprites/enemy.png" id="1_tex"]` appears after the first `[node]` block.
- **Problem:** Godot .tscn format requires strict section ordering: all `[ext_resource]` entries first, then all `[sub_resource]` entries, then all `[node]` entries.
- **Fix:** Move all `[ext_resource]` blocks to the top of the file, immediately after the `[gd_scene]` header.

## Error 5: `[sub_resource]` declared after `[node]`

- **Line:** `[sub_resource type="CircleShape2D" id="CircleShape2D_abc"]` appears after the first `[node]` block.
- **Problem:** Same ordering rule as Error 4. All `[sub_resource]` entries must come after `[ext_resource]` entries but before any `[node]` entries.
- **Fix:** Move the `[sub_resource]` block to appear after ext_resources but before nodes.

## Error 6: Child node uses root node name as parent instead of `"."`

- **Line:** `[node name="Sprite2D" type="Sprite2D" parent="Enemy"]`
- **Problem:** In .tscn files, `parent` is a path relative to the root node. Direct children of the root must use `parent="."`, not `parent="RootNodeName"`. The root node itself has no `parent` attribute.
- **Fix:** Change to `[node name="Sprite2D" type="Sprite2D" parent="."]`.

## Error 7: CollisionShape2D node missing `parent` attribute

- **Line:** `[node name="CollisionShape2D" type="CollisionShape2D"]`
- **Problem:** Only the root node omits the `parent` attribute. All other nodes must specify `parent`. Without it, Godot would interpret this as a second root node, which is invalid.
- **Fix:** Change to `[node name="CollisionShape2D" type="CollisionShape2D" parent="."]`.

## Error 8: SubResource ID mismatch

- **Line:** `shape = SubResource("CircleShape2D_xyz")`
- **Problem:** The `[sub_resource]` was declared with `id="CircleShape2D_abc"` but is referenced here as `"CircleShape2D_xyz"`. These IDs must match exactly.
- **Fix:** Change to `shape = SubResource("CircleShape2D_abc")` to match the declared ID.
