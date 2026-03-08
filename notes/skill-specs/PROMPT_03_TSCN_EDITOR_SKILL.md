# Session Prompt: Build the `tscn-editor` Skill

> Copy-paste this entire file as the first message in a new Claude Code session.
> Working directory: `D:\Workspace\Games\claude-game-dev`

---

## Your Task

Build a Claude Code skill called `tscn-editor` — a **file format skill for safely editing Godot .tscn and .tres files**. This skill should activate whenever Claude Code needs to read, write, or modify Godot scene or resource files directly.

## Mandatory Reading (do this FIRST)

Before doing anything else, read these files to understand the context:

1. `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\03-mistakes-and-fixes.md` — Several bugs were caused by incorrect .tscn editing.
2. `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\05-improvement-suggestions.md` — Section on .tscn editing patterns and template files.
3. `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\06-skill-building-notes.md` — Domain 1 covers Godot file formats in detail.
4. `D:\Workspace\Games\claude-game-dev\examples\forge-of-worlds\CLAUDE.md` — Anti-patterns section has .tscn-specific rules.

**Critical: Research the .tscn format thoroughly before building the skill.** Read:
- The actual .tscn files in `examples/forge-of-worlds/scenes/` — study the real format
- Godot docs on the .tscn format: search for "Godot TSCN file format" and "Godot scene format specification"
- Search GitHub for common .tscn editing patterns in CI/CD and automation contexts

## How This Skill Fits Into the Bigger Picture

| Skill | Level | Purpose |
|-------|-------|---------|
| gdscript | Language | GDScript syntax and patterns |
| godot (exists) | Engine | Godot architecture and node types |
| godot-mcp | Tooling | MCP tool usage and workflow |
| **tscn-editor** (THIS ONE) | File format | Safe .tscn/.tres editing rules |
| game-creation (to be built) | Workflow | Game creation orchestration |

The Godot MCP cannot do everything — it can't attach scripts, set complex properties (Vector2, Color), create sub-resources (collision shapes, fonts), or instance sub-scenes. These gaps are filled by directly editing .tscn files via Claude Code's Write/Edit tools. This skill makes those edits **safe and correct**.

**Why this skill matters:** .tscn files look simple (they're text), but they have strict formatting rules. An LLM getting the format wrong produces silent corruption — the scene loads but behaves unexpectedly, or Godot re-saves it differently. This skill prevents those errors.

## Skill Purpose

Ensure that ALL direct .tscn/.tres file edits by Claude Code are syntactically correct, follow Godot's format conventions, and don't corrupt scene files. The skill acts as a format validator and reference.

## Skill Triggers

The skill should activate when:
- Writing or editing any `.tscn` file
- Writing or editing any `.tres` file
- Attaching a script to a scene node
- Adding collision shapes, physics properties, or other sub-resources
- Setting complex property types (Vector2, Color, Rect2, etc.)
- Fixing merge conflicts in .tscn files
- Creating .tscn files from scratch (without MCP)

## Key Content to Include

### .tscn File Structure

A .tscn file has this STRICT ordering:
```
[gd_scene load_steps=N format=3 uid="uid://..."]

[ext_resource type="Script" path="res://scripts/player.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/sprites/player.png" id="2"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_abc12"]
size = Vector2(16, 16)

[sub_resource type="CircleShape2D" id="CircleShape2D_def34"]
radius = 64.0

[node name="Player" type="CharacterBody2D"]
script = ExtResource("1")
speed = 100.0

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_abc12")
```

### MUST DO Rules
1. **`load_steps` must equal the total count of ext_resource + sub_resource blocks + 1.** Godot recalculates this on save, so getting it wrong won't crash, but it signals a malformed file.
2. **ext_resource blocks MUST come before sub_resource blocks, which MUST come before node blocks.** This ordering is mandatory.
3. **Each ext_resource and sub_resource needs a unique ID.** For ext_resource: use sequential integers ("1", "2", "3"). For sub_resource: use Godot's format `TypeName_xxxxx` where xxxxx is random alphanumeric.
4. **Reference ext_resources with `ExtResource("id")`** and sub_resources with `SubResource("id")`.
5. **Script attachment:** Add `script = ExtResource("N")` to the root node block, where N is the ext_resource ID of the .gd file.
6. **Parent paths:** Root node has no parent. Direct children use `parent="."`. Deeper nodes use `parent="ParentName"` or `parent="Parent/Child"`.
7. **Property serialization:** Vector2 → `Vector2(x, y)`, Color → `Color(r, g, b, a)`, bool → `true/false`, int → bare number, float → number with decimal.
8. **Collision layers/masks are integers**, not bitmask strings. Layer 1+2 = 3, Layer 1+3 = 5, etc.

### MUST NOT Rules
1. **Never use `var`, `const`, `func`, or any GDScript syntax in .tscn files** — these are resource files, not scripts.
2. **Never use `preload()` or `load()` in .tscn files** — use `ExtResource()` or `SubResource()`.
3. **Never put node blocks before ext_resource or sub_resource blocks.**
4. **Never reuse ext_resource or sub_resource IDs** within the same file.
5. **Never set properties that don't exist on the node type** — Godot silently ignores them but it indicates a bug.
6. **Never edit .tscn files that are open in the Godot editor** — the editor will overwrite your changes on save.

### Common Edit Patterns

#### Attaching a script to a scene
```
# Add to ext_resource section:
[ext_resource type="Script" path="res://scripts/player/player.gd" id="3"]

# Add to root node:
[node name="Player" type="CharacterBody2D"]
script = ExtResource("3")
```

#### Adding a collision shape
```
# Add to sub_resource section:
[sub_resource type="RectangleShape2D" id="RectangleShape2D_body1"]
size = Vector2(12, 12)

# Reference in node:
[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_body1")
```

#### Setting collision layers
```
[node name="Player" type="CharacterBody2D"]
collision_layer = 2
collision_mask = 1
```

#### Setting complex properties
```
[node name="Camera2D" type="Camera2D" parent="."]
zoom = Vector2(2, 2)
position_smoothing_enabled = true
position_smoothing_speed = 8.0
```

### Validation Checklist (Before Saving)
After editing a .tscn file, verify:
- [ ] All ext_resource paths are valid (files exist at those res:// paths)
- [ ] All sub_resource IDs are unique
- [ ] All ExtResource() and SubResource() references point to existing IDs
- [ ] Node parent paths are correct
- [ ] load_steps count is approximately correct
- [ ] No GDScript syntax in the file
- [ ] File structure order: gd_scene → ext_resource → sub_resource → node

## Deliverable

Create the skill at: `D:\Workspace\Games\claude-game-dev\.claude\skills\tscn-editor\SKILL.md`

Follow `/skill-creator` best practices:
- Focus on SAFETY — this skill prevents silent file corruption
- Include the validation checklist as an always-run step
- Keep it lean but thorough on format rules
- Ground in real .tscn files from the examples

## Quality Check

After creating:
1. Does it cover the complete .tscn structure?
2. Does it include the validation checklist?
3. Does it handle the most common edit patterns (script attachment, collision shapes, complex properties)?
4. Does it warn against the silent-corruption pitfalls?
5. Can Claude follow these rules and produce a valid .tscn file from scratch?
