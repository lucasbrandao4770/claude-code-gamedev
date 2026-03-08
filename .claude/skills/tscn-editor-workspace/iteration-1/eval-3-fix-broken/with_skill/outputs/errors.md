# Errors Found in broken .tscn

## Error 1: Section ordering violation
**Location:** Lines 3-10 (nodes before ext_resource and sub_resource)
**Rule:** Sections must appear in strict order: header -> ext_resource -> sub_resource -> node -> connection.
**Problem:** The root `[node]` block appears immediately after the header, before the `[ext_resource]` and `[sub_resource]` blocks. This corrupts the file because Godot's parser expects ext_resources and sub_resources to be declared before any nodes reference them.
**Fix:** Move `[ext_resource]` and `[sub_resource]` blocks above all `[node]` blocks.

## Error 2: `preload()` used in .tscn file
**Location:** `script = preload("res://scripts/enemy.gd")`
**Rule:** Never use `preload()`, `load()`, or any GDScript syntax in .tscn files. Scripts must be declared as ext_resources and referenced via `ExtResource()`.
**Problem:** `preload()` is GDScript — it causes a parse error in a .tscn file.
**Fix:** Add `[ext_resource type="Script" path="res://scripts/enemy.gd" id="1_script"]` and change the property to `script = ExtResource("1_script")`.

## Error 3: Invalid Vector2 syntax
**Location:** `position = (100, 200)`
**Rule:** Vector2 values must use the constructor syntax `Vector2(x, y)`, not bare tuple `(x, y)`.
**Problem:** `(100, 200)` is not valid .tscn property syntax. Godot will silently ignore this property.
**Fix:** Change to `position = Vector2(100, 200)`.

## Error 4: Wrong parent path for Sprite2D node
**Location:** `[node name="Sprite2D" type="Sprite2D" parent="Enemy"]`
**Rule:** Direct children of the root node use `parent="."`, not the root node's name. The root's name is only used as a path segment for deeper descendants (e.g., `parent="Enemy/SubChild"`).
**Problem:** `parent="Enemy"` tells Godot to look for a node named "Enemy" under the root, but "Enemy" IS the root. This creates an orphan node or crashes on load.
**Fix:** Change to `parent="."`.

## Error 5: Missing parent attribute on CollisionShape2D
**Location:** `[node name="CollisionShape2D" type="CollisionShape2D"]`
**Rule:** Only the root node (the first `[node]` block) omits the `parent` attribute. Every other node must have one.
**Problem:** This is the third node in the file but has no `parent` attribute, making Godot treat it as a second root node (which is invalid) or causing a parse error.
**Fix:** Add `parent="."` (assuming it is a direct child of the root).

## Error 6: Dangling SubResource reference (mismatched ID)
**Location:** `shape = SubResource("CircleShape2D_xyz")`
**Rule:** Every `SubResource("id")` must reference an existing `[sub_resource]` block with a matching `id`.
**Problem:** The sub_resource is declared with `id="CircleShape2D_abc"` but referenced as `SubResource("CircleShape2D_xyz")`. The IDs don't match, so the shape resolves to null and collision silently fails.
**Fix:** Change the reference to `SubResource("CircleShape2D_abc")` to match the declared ID.
