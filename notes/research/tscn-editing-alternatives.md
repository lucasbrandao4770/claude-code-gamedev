# Alternatives to Direct .tscn File Editing in AI-Assisted Godot Development

**Date:** 2026-03-08
**Context:** Claude Code + Godot MCP workflow for building Godot 4.x games
**Problem:** Direct .tscn text editing is fragile — LLMs can introduce silent corruption in the strict format

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Current Gap Analysis](#current-gap-analysis)
3. [Approach 1: Godot CLI Headless Scripting](#approach-1-godot-cli-headless-scripting)
4. [Approach 2: EditorScript](#approach-2-editorscript)
5. [Approach 3: @tool Scripts](#approach-3-tool-scripts)
6. [Approach 4: Alternative MCP Servers](#approach-4-alternative-mcp-servers)
7. [Approach 5: Python tscn Parsing Libraries](#approach-5-python-tscn-parsing-libraries)
8. [Approach 6: Direct .tscn Editing (Current)](#approach-6-direct-tscn-editing-current)
9. [.tscn Format Stability Analysis](#tscn-format-stability-analysis)
10. [Comparison Table](#comparison-table)
11. [Recommendation](#recommendation)

---

## Executive Summary

**The best approach is to switch to the GDAI MCP plugin (3ddelano/gdai-mcp-plugin-godot)**, which solves all identified gaps (script attachment, complex properties, sub-resources, sub-scene instancing) through Godot's own API. It includes an `execute_editor_script` tool that serves as an escape hatch for anything not covered by the 31 built-in tools.

For cases where the editor cannot be running (CI/CD, offline generation), the **Godot CLI headless scripting** approach using `godot --headless --script` with a SceneTree-extending script provides a robust fallback that uses Godot's own serializer, guaranteeing valid .tscn output.

Direct .tscn editing should be eliminated from the workflow entirely.

---

## Current Gap Analysis

Our current MCP (Coding-Solo/godot-mcp) can:
- Launch the editor and run projects
- Create scenes and add basic nodes
- Capture debug output

It **cannot**:
| Gap | Impact |
|-----|--------|
| Attach scripts to scene nodes | Must manually edit .tscn to add `script = ExtResource(...)` |
| Set complex properties (Vector2, Color, collision layers) | Must manually write serialized values like `Vector2(100, 200)` |
| Create sub-resources (CollisionShape2D shapes, materials) | Must manually write `[sub_resource]` blocks |
| Instance sub-scenes | Must manually add ext_resource + instance reference |

We currently fill these gaps by having Claude Code edit .tscn files with the Edit tool. This works but is fragile because:
- .tscn has strict formatting rules (exact whitespace, resource ID ordering, UID format)
- LLMs can introduce subtle errors (wrong ID references, missing `set_owner`, bad value serialization)
- Godot's external file reload is buggy — it doesn't always detect changes, especially for non-active scenes ([Issue #73602](https://github.com/godotengine/godot/issues/73602), [Issue #75865](https://github.com/godotengine/godot/issues/75865))

---

## Approach 1: Godot CLI Headless Scripting

### How It Works

Godot 4.x supports running GDScript from the command line:

```bash
godot --headless --script res://tools/setup_scene.gd
```

The script must extend `SceneTree` or `MainLoop`. It runs Godot's full engine in headless mode (no window), executes the script, and exits.

### Can It Modify Scenes?

**Yes.** A headless script can load a PackedScene, instantiate it, modify nodes, and save back:

```gdscript
# setup_scene.gd
extends SceneTree

func _init():
    # Load existing scene
    var packed = load("res://scenes/player.tscn") as PackedScene
    var root = packed.instantiate()

    # Add a new node
    var collision = CollisionShape2D.new()
    var shape = CircleShape2D.new()
    shape.radius = 16.0
    collision.shape = shape
    root.add_child(collision)
    collision.owner = root  # CRITICAL: must set owner for serialization

    # Attach a script
    var script = load("res://scripts/player.gd")
    root.set_script(script)

    # Set complex properties
    root.position = Vector2(100, 200)
    root.modulate = Color(1, 0.5, 0.3, 1)

    # Save back
    var new_packed = PackedScene.new()
    new_packed.pack(root)
    ResourceSaver.save(new_packed, "res://scenes/player.tscn")

    # Clean up and exit
    root.queue_free()
    quit()
```

### Key Requirements

1. **`owner` must be set** — Any node added via `add_child()` must have `node.owner = root` set, or it won't be serialized into the .tscn file. This is the #1 gotcha.
2. **Script extends SceneTree** — Not `Node`, not `EditorScript`. The `_init()` method runs immediately.
3. **Must call `quit()`** — Otherwise the process hangs.
4. **Must be inside a Godot project** — The script must be at a `res://` path within a valid project (with `project.godot`).

### Capabilities

| Operation | Supported? | Notes |
|-----------|-----------|-------|
| Load existing .tscn | Yes | `load("res://scene.tscn").instantiate()` |
| Add nodes | Yes | Standard `add_child()` + `set_owner()` |
| Attach scripts | Yes | `node.set_script(load("res://script.gd"))` |
| Set Vector2/Vector3 | Yes | Direct property assignment |
| Set Color | Yes | Direct property assignment |
| Set collision layers/masks | Yes | `node.collision_layer = 0b0001` |
| Create sub-resources | Yes | Create resource objects in code, assign to nodes |
| Instance sub-scenes | Yes | `load("res://sub.tscn").instantiate()` + add_child |
| Create new scenes from scratch | Yes | Create Node tree, pack, save |

### Limitations

- No access to `EditorInterface` — cannot interact with editor-specific features
- No undo/redo — the save is final
- Requires Godot binary in PATH or explicit path
- Script must be inside the project directory
- Cannot run editor plugins or use editor-only classes

### Community Usage

This approach is used in:
- CI/CD pipelines for batch asset processing
- Procedural content generation pipelines (Python generates data, GDScript generates scenes)
- Automated testing frameworks
- Custom importers/exporters

### Sources
- [Godot Proposals: Allow running headless editor scripts (#8664)](https://github.com/godotengine/godot-proposals/discussions/8664)
- [Godot Docs: Command line tutorial](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
- [Godot Forum: How to create a .tscn file](https://forum.godotengine.org/t/how-to-create-a-tscn-file/69929?page=2)

---

## Approach 2: EditorScript

### How It Works

EditorScript is a special class that runs inside the Godot editor. You create a script extending `EditorScript`, and run it via **File > Run** (or Ctrl+Shift+X) while the script is open in the Script Editor.

```gdscript
# tools/add_collision.gd
@tool
extends EditorScript

func _run():
    var scene = get_scene()  # Gets currently open scene root

    # Add a CollisionShape2D to a specific node
    var player = scene.get_node("Player")
    var collision = CollisionShape2D.new()
    var shape = RectangleShape2D.new()
    shape.size = Vector2(32, 48)
    collision.shape = shape
    player.add_child(collision)
    collision.owner = scene  # MUST set owner to scene root, not parent

    # Attach script
    var script = load("res://scripts/player_controller.gd")
    player.set_script(script)

    print("Done! Save the scene.")
```

### Critical Gotchas

1. **`set_owner(get_scene())`** — Even when adding to a sub-node, owner must always be the scene root (returned by `get_scene()`), not the immediate parent.
2. **Must be `@tool`** — The script must have `@tool` annotation to work as an EditorScript.
3. **No undo** — Changes are immediate and irreversible. Save before running.
4. **Must save manually** — The script modifies the in-memory scene; you must save the scene yourself after running.

### Can It Be Triggered from CLI?

**Not directly.** EditorScript requires the editor to be open and the script to be the active script in the Script Editor. However, there is a workaround:

```bash
godot --editor --headless res://scenes/main.tscn
```

This opens the editor headlessly with a specific scene. Combined with a `@tool` script on the root node that runs its logic in `_ready()`, you can achieve similar automation. In Godot 4.2+, `EditorInterface` is available as a singleton in this mode.

However, this approach is fragile and not officially supported for automation. The [godot-proposals #8664](https://github.com/godotengine/godot-proposals/discussions/8664) discussion requests official support for headless EditorScript execution.

### Capabilities

Same as CLI headless scripting, plus access to `EditorInterface` and editor-specific singletons. Can interact with the currently open scene without load/save gymnastics.

### Limitations

- Requires editor to be running with the script open
- Cannot be triggered programmatically from outside Godot (no CLI trigger)
- No undo/redo support
- Not viable for automated pipelines

### Sources
- [Godot Docs: EditorScript class](https://docs.godotengine.org/en/stable/classes/class_editorscript.html)
- [Godot Docs: Running code in the editor](https://docs.godotengine.org/en/4.4/tutorials/plugins/running_code_in_the_editor.html)
- [Godot Forum: How to use EditorScript to create Nodes](https://forum.godotengine.org/t/how-to-use-editorscript-to-create-nodes/33647)
- [Godot Forum: Adding a node to a scene file via an editor script](https://forum.godotengine.org/t/adding-a-node-to-a-scene-file-via-an-editor-script/39625)

---

## Approach 3: @tool Scripts

### How It Works

Adding `@tool` at the top of any GDScript makes it execute in the editor. The script's `_ready()`, `_process()`, and other lifecycle methods run in real-time as you edit scenes.

```gdscript
# player.gd
@tool
extends CharacterBody2D

func _ready():
    if Engine.is_editor_hint():
        # Only run in editor
        _setup_collision()

func _setup_collision():
    if not has_node("CollisionShape2D"):
        var col = CollisionShape2D.new()
        var shape = CapsuleShape2D.new()
        shape.radius = 12.0
        shape.height = 32.0
        col.shape = shape
        add_child(col)
        col.owner = owner  # Set to scene root
```

### Viability for Automation

**Not viable.** @tool scripts are designed for editor-time visualization and interaction (preview custom nodes, draw gizmos, etc.). They:

- Run every time the scene loads in the editor, not on demand
- Can cause editor instability if they modify the scene tree during editor operations
- Require the scene to be open in the editor
- Have no CLI trigger mechanism
- Any child GDScript used by a @tool script must also be @tool

### When @tool Is Useful

- Custom node types that need editor previews
- Level design tools (tile painters, path editors)
- Procedural content that needs real-time editor preview

### Sources
- [Godot Docs: Running code in the editor](https://docs.godotengine.org/en/stable/tutorials/plugins/running_code_in_the_editor.html)
- [DeepWiki: Tool Scripts](https://deepwiki.com/godotengine/godot-docs/8.2-tool-scripts)

---

## Approach 4: Alternative MCP Servers

### GDAI MCP (3ddelano/gdai-mcp-plugin-godot) — RECOMMENDED

**Website:** https://gdaimcp.com
**GitHub:** https://github.com/3ddelano/gdai-mcp-plugin-godot
**Godot version:** 4.2+
**Tools:** 31 tools

This is the most complete MCP for our use case. It runs as a Godot editor plugin, meaning it uses Godot's own API for all operations.

#### Gap Resolution

| Gap | Tool | How It Works |
|-----|------|-------------|
| Attach scripts to nodes | `attach_script` | "Attach a script file to a node in the scene" |
| Set complex properties | `update_property` | "Update a property of a given node" |
| Create sub-resources | `add_resource` | "Add a new resource or subresource as a property to a node" |
| Instance sub-scenes | `add_scene` | "Add a scene as a node to a parent node in the current scene" |
| Anything else | `execute_editor_script` | "Execute arbitrary GDScript in the Editor as a tool script" |

#### Complete Tool List

**Project Tools (5):** get_project_info, get_filesystem_tree, search_files, uid_to_project_path, project_path_to_uid

**Scene Tools (8):** get_scene_tree, get_scene_file_content, create_scene, open_scene, delete_scene, add_scene, play_scene, stop_running_scene

**Node Tools (8):** add_node, delete_node, duplicate_node, move_node, update_property, add_resource, set_anchor_preset, set_anchor_values

**Script Tools (5):** get_open_scripts, view_script, create_script, attach_script, edit_file

**Editor Tools (5):** get_godot_errors, get_editor_screenshot, get_running_scene_screenshot, execute_editor_script, clear_output_logs

#### Key Advantage: execute_editor_script

This tool is the escape hatch. It can run arbitrary GDScript inside the editor context, meaning anything Godot can do, this tool can do. If a specific tool doesn't cover a use case, Claude can write a GDScript snippet and execute it via this tool.

#### Requirements

- Godot editor must be running with the plugin enabled
- MCP client must be configured to connect to the plugin

---

### tugcantopaloglu/godot-mcp — Most Tools (149)

**GitHub:** https://github.com/tugcantopaloglu/godot-mcp
**Tools:** 149 tools

This is a fork of Coding-Solo/godot-mcp with massive additions. It operates through two interfaces:

1. **Headless CLI** — Runs `godot --headless --script godot_operations.gd` for operations that don't need a running game (scene reading, modification, resource creation)
2. **TCP Socket** — `mcp_interaction_server.gd` autoload listens on port 9090 for runtime interaction

#### Gap Resolution

| Gap | Tool | Notes |
|-----|------|-------|
| Attach scripts | `attach_script` | Headless operation |
| Set complex properties | `modify_scene_node` | Smart property type detection using `get_property_list()` for automatic conversion. Supports Vector2/3, Color, Quaternion, Basis, Transform2D/3D, AABB, Rect2, all packed arrays |
| Create sub-resources | `create_resource` | Creates .tres files; `game_add_collision` for collision shapes |
| Instance sub-scenes | `game_instantiate_scene` | Runtime instancing |

#### Key Advantages

- Headless operations work without the editor running
- Smart type detection auto-converts string values to correct Godot types
- 149 tools cover nearly every Godot operation
- Runtime interaction via TCP for testing

#### Concerns

- Very large tool surface area (149 tools may overwhelm the LLM's context)
- Fork of Coding-Solo — maintenance/community support unclear
- TCP-based runtime interaction adds complexity

---

### ee0pdt/Godot-MCP

**GitHub:** https://github.com/ee0pdt/Godot-MCP
**Tools:** ~15 commands

This MCP has a **known bug preventing script attachment** ([Issue #14](https://github.com/ee0pdt/Godot-MCP/issues/14)). The `update_node_property()` function reports success when setting the script property but the script doesn't actually execute. The bug is open and unresolved as of this writing.

**Verdict:** Not recommended due to the script attachment bug.

---

### bradypp/godot-mcp

**GitHub:** https://github.com/bradypp/godot-mcp

Another MCP with basic capabilities (create_scene, add_node, edit_node). No evidence of script attachment, sub-resource creation, or complex property support. Primarily focused on scene structure and debug output.

**Verdict:** Insufficient for our needs.

---

### Sources
- [GDAI MCP Supported Tools](https://gdaimcp.com/docs/supported-tools)
- [tugcantopaloglu/godot-mcp README](https://github.com/tugcantopaloglu/godot-mcp)
- [ee0pdt/Godot-MCP Issue #14](https://github.com/ee0pdt/Godot-MCP/issues/14)
- [bradypp/godot-mcp](https://github.com/bradypp/godot-mcp)

---

## Approach 5: Python tscn Parsing Libraries

### godot_parser (stevearc/godot_parser)

**PyPI:** https://pypi.org/project/godot-parser/
**Version:** 0.1.7 (released 2023-10-01)
**Status:** Alpha, low maintenance activity

A Python library for parsing and modifying .tscn and .tres files with two API levels:

**High-level API example:**
```python
from godot_parser import GDScene, Node

scene = GDScene()
res = scene.add_ext_resource("res://PlayerSprite.png", "PackedScene")
with scene.use_tree() as tree:
    tree.root = Node("Player", type="KinematicBody2D")
    tree.root.add_child(
        Node("Sprite", type="Sprite",
             properties={"texture": res.reference})
    )
scene.write("Player.tscn")
```

**Modification example:**
```python
from godot_parser import load

scene = load("scene.tscn")
with scene.use_tree() as tree:
    sensor = tree.get_node("Sensor")
    if sensor:
        sensor["collision_layer"] = 5
scene.write("scene.tscn")
```

#### Concerns

| Issue | Impact |
|-------|--------|
| Alpha status | May have undiscovered bugs |
| Last release 2023-10 | May not support Godot 4.4 UID changes |
| "Based on visual inspection" | Not based on official spec — fragile |
| No scene inheritance modification | Limited for complex scenes |
| Godot 4 format=3 support unclear | May generate invalid files for Godot 4 |

#### Verdict

This is essentially the same approach as direct .tscn editing but with a Python abstraction layer. It's still fragile because:
- It's reverse-engineered from file inspection, not based on the official format
- It may not handle Godot 4.4's UID system correctly
- Any format change in a Godot update could break it
- It doesn't use Godot's own serializer, so it can produce subtly invalid files

**Not recommended as primary approach.** Could be useful as a fallback for CI/CD scenarios where Godot binary is unavailable.

### Other Libraries

- **godot-tscn-parser-py** (RikaKagurasaka) — Converts TSCN to JSON. Read-only, no write support.
- **godotclj-tscn** — Clojure-based parser/emitter. Niche.

### Sources
- [godot_parser GitHub](https://github.com/stevearc/godot_parser)
- [godot-parser PyPI](https://pypi.org/project/godot-parser/)

---

## Approach 6: Direct .tscn Editing (Current)

### How It Works

Claude Code uses the Edit tool to directly modify .tscn text files, inserting/modifying `[ext_resource]`, `[sub_resource]`, and `[node]` blocks.

### .tscn Format Quick Reference (Godot 4.x, format=3)

```
[gd_scene load_steps=4 format=3 uid="uid://cecaux1sm7mo0"]

[ext_resource type="Script" uid="uid://abc123" path="res://player.gd" id="1_abc"]
[ext_resource type="PackedScene" uid="uid://def456" path="res://bullet.tscn" id="2_def"]

[sub_resource type="CircleShape2D" id="CircleShape2D_xyz"]
radius = 16.0

[node name="Player" type="CharacterBody2D"]
script = ExtResource("1_abc")
position = Vector2(100, 200)
collision_layer = 1
collision_mask = 3

[node name="CollisionShape" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_xyz")

[node name="Sprite" type="Sprite2D" parent="."]
texture = ExtResource("2_def")
modulate = Color(1, 0.5, 0.3, 1)

[connection signal="body_entered" from="." to="." method="_on_body_entered"]
```

### Risks of Direct Editing

| Risk | Description |
|------|-------------|
| ID mismatch | Referencing an ext_resource/sub_resource ID that doesn't exist silently breaks the scene |
| UID format errors | Godot 4.4 uses `uid://` format UIDs; wrong format = warnings |
| load_steps wrong | Must equal total resources + 1; wrong value affects loading bars |
| Missing owner semantics | Text format doesn't encode owner, but node parent path implicitly defines it |
| Property serialization | Complex types must use exact syntax: `Vector2(x, y)`, `Color(r, g, b, a)` |
| Whitespace sensitivity | Extra blank lines or wrong indentation can cause parse errors |
| Reload bugs | Godot doesn't always detect external modifications to .tscn files |

### Sources
- [Godot Docs: TSCN file format](https://docs.godotengine.org/en/4.4/contributing/development/file_formats/tscn.html)
- [Godot Issue #73602: Doesn't always reload externally modified .tscn files](https://github.com/godotengine/godot/issues/73602)
- [Godot Issue #75865: Reliably reload externally modified scenes](https://github.com/godotengine/godot/issues/75865)

---

## .tscn Format Stability Analysis

### Format Version History

| Godot Version | Format Version | Key Changes |
|---------------|---------------|-------------|
| 3.x | format=2 | Integer resource IDs |
| 4.0 | format=3 | String-based UIDs, new mesh/skeleton/animation data |
| 4.3 | format=3 | PackedByteArray switched to Base64 encoding |
| 4.4 | format=3 | UIDs extended to scripts and shaders; `.uid` companion files |

### Stability Assessment

**The format is NOT fully stable across Godot 4.x releases.** While the major structure (format=3) hasn't changed, subtle changes occur:

1. **Godot 4.3** changed PackedByteArray serialization to Base64, breaking backward compatibility with 4.2
2. **Godot 4.4** introduced `.uid` files for scripts/shaders and changed how resource references are stored
3. **The format documentation is incomplete** — the [official docs issue #6769](https://github.com/godotengine/godot-docs/issues/6769) for updating the TSCN format docs for Godot 4.0 was opened in 2023 and the docs still reference format=2 examples in many places

### Is It Officially Documented for External Tools?

**Partially.** The format is documented but:
- The docs acknowledge it's "mostly human-readable" and intended for version control
- There is no formal spec or JSON schema
- The docs say `load_steps` being wrong is tolerated but affects loading bars
- External tools are not officially supported — Godot's serializer is the source of truth

### Parsing Libraries

| Library | Language | Godot 4 Support | Status |
|---------|----------|-----------------|--------|
| godot_parser | Python | Unclear (alpha) | Low maintenance |
| godot-tscn-parser-py | Python | Unknown | Read-only |
| godotclj-tscn | Clojure | Unknown | Niche |
| godot-tscn-source-generator | C# | Yes | Generates C# from TSCN |

### Sources
- [UID changes coming to Godot 4.4](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/)
- [Godot Docs Issue #6769: Update TSCN format docs for 4.0](https://github.com/godotengine/godot-docs/issues/6769)

---

## Comparison Table

| Criteria | Direct .tscn Edit | CLI Headless Script | EditorScript | GDAI MCP | tugcantopaloglu MCP | Python godot_parser |
|----------|-------------------|-------------------|-------------|----------|-------------------|-------------------|
| **Attach scripts** | Manual (fragile) | Yes (set_script) | Yes (set_script) | Yes (attach_script) | Yes (attach_script) | Possible (manual) |
| **Complex properties** | Manual (fragile) | Yes (native API) | Yes (native API) | Yes (update_property) | Yes (smart type detection) | Partial |
| **Sub-resources** | Manual (fragile) | Yes (create in code) | Yes (create in code) | Yes (add_resource) | Yes (create_resource) | Manual (fragile) |
| **Sub-scene instancing** | Manual (fragile) | Yes (instantiate) | Yes (instantiate) | Yes (add_scene) | Yes (game_instantiate_scene) | Manual (fragile) |
| **Requires editor running** | No | No | Yes | Yes | Partial (headless + TCP) | No |
| **Requires Godot binary** | No | Yes | Yes | Yes | Yes | No |
| **Uses Godot's serializer** | No | Yes | Yes | Yes | Yes | No |
| **Format stability risk** | HIGH | None | None | None | None | HIGH |
| **LLM corruption risk** | HIGH | LOW (code is standard GDScript) | LOW | NONE (API calls) | NONE (API calls) | MEDIUM |
| **Escape hatch for edge cases** | N/A | Full GDScript | Full GDScript + EditorInterface | execute_editor_script | game_eval (arbitrary code) | N/A |
| **Automation-friendly** | Yes | Yes | No (manual trigger) | Yes (MCP protocol) | Yes (MCP protocol) | Yes |
| **Setup complexity** | None | Low | Low | Medium (plugin install) | Medium (plugin + server) | Low (pip install) |

---

## Recommendation

### Primary: Switch to GDAI MCP (3ddelano/gdai-mcp-plugin-godot)

**Why:**
1. Solves ALL identified gaps through dedicated tools
2. Uses Godot's own API — zero risk of format corruption
3. `execute_editor_script` provides an escape hatch for any unlisted operation
4. Screenshots of editor and running game for visual verification
5. Error/debugger integration for fast iteration
6. Actively maintained, well-documented at gdaimcp.com
7. Works with Claude Code, Cursor, VSCode, and other MCP clients

**Setup cost:** Install the plugin in the Godot project, configure MCP client to connect. One-time effort.

**Trade-off:** Requires the Godot editor to be running. This is acceptable for our interactive development workflow.

### Secondary: CLI Headless Scripts for Batch Operations

**When to use:**
- CI/CD pipelines
- Batch scene generation (procedural levels)
- Offline processing without the editor
- Creating a scene from a template programmatically

**Pattern:**
```bash
# Claude Code writes the GDScript setup file
# Then invokes Godot to run it
godot --headless --script res://tools/setup_level.gd -- --level=3
```

The GDScript is standard code that Claude can write reliably (unlike .tscn format), and Godot's own serializer guarantees valid output.

### Eliminate: Direct .tscn Editing

Direct .tscn editing should be completely eliminated from the workflow. Every operation that currently requires it has a better alternative:

| Current .tscn Edit | Replace With |
|---------------------|-------------|
| Add `[ext_resource]` for script | GDAI MCP `attach_script` |
| Add `[sub_resource]` for collision shape | GDAI MCP `add_resource` |
| Set `position = Vector2(...)` | GDAI MCP `update_property` |
| Add instanced sub-scene | GDAI MCP `add_scene` |
| Complex multi-step setup | GDAI MCP `execute_editor_script` or CLI headless script |

### Action Items

1. **Install GDAI MCP plugin** in the Godot project (`addons/gdai-mcp-plugin-godot/`)
2. **Configure MCP client** (Claude Code) to connect to GDAI MCP
3. **Test the critical tools**: `attach_script`, `add_resource`, `update_property`, `add_scene`
4. **Create a CLI headless script template** (`res://tools/scene_setup_template.gd`) for batch operations
5. **Remove all .tscn editing logic** from our workflow/skills
6. **Document the new workflow** in the project's development guide

---

*Research conducted 2026-03-08 using web sources, Godot documentation, GitHub repositories, and community forums.*
