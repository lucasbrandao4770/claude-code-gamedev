# Setting Up a Fresh Godot 4.x Project with godot-mcp

Here is a complete walkthrough to go from zero to a working Claude Code + Godot MCP setup.

---

## Prerequisites

Before starting, make sure you have:

1. **Godot 4.x** installed (Steam, standalone, or Scoop -- any distribution works)
2. **Node.js 18+** installed (needed to run the MCP server)
3. **Git** installed
4. **Claude Code** CLI installed and authenticated

Find your Godot executable path -- you will need it. Examples:
- Steam: `D:/Games/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe`
- Standalone: `C:/Godot/Godot_v4.4-stable_win64.exe`
- Linux: `/usr/bin/godot` or wherever you installed it

---

## Step 1: Clone and Build godot-mcp

The MCP server bridges Claude Code and Godot. Clone it somewhere permanent outside your game project:

```bash
# Pick a location for your MCP servers
mkdir -p ~/mcps && cd ~/mcps

# Clone the repo
git clone https://github.com/Coding-Solo/godot-mcp.git
cd godot-mcp

# Install dependencies and build
npm install
npm run build
```

After this, note the absolute path to `build/index.js` inside the cloned repo. For example:
`D:/Workspace/mcps/godot-mcp/build/index.js`

---

## Step 2: Create Your Godot Project Folder

Create a folder for your game and initialize it:

```bash
mkdir -p ~/games/my-game
cd ~/games/my-game
git init
```

---

## Step 3: Create `project.godot`

Every Godot project needs a `project.godot` file at its root. You can either:

**Option A: Open Godot, create a new project pointing to your folder** -- this generates the file automatically.

**Option B: Write it by hand** (useful when working headlessly with Claude Code). Here is a minimal starter for a 2D pixel art game:

```ini
; Engine configuration file.
; It's best edited using the editor UI and not directly,
; but it can also be manually edited.

config_version=5

[application]

config/name="My Game"
config/features=PackedStringArray("4.4", "GL Compatibility")
run/main_scene=""

[display]

window/size/viewport_width=640
window/size/viewport_height=360
window/stretch/mode="viewport"
window/stretch/aspect="keep"

[rendering]

textures/canvas_textures/default_texture_filter=0
renderer/rendering_method="gl_compatibility"
```

Key settings for pixel art:
- `default_texture_filter=0` sets Nearest filtering globally (crisp pixels, no blurring)
- `window/stretch/mode="viewport"` ensures pixel-perfect scaling
- Viewport size of 640x360 gives a good 16:9 pixel art canvas

---

## Step 4: Set Up the MCP Configuration

Create a `.mcp.json` file in your project root:

```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["<ABSOLUTE_PATH_TO>/godot-mcp/build/index.js"],
      "env": {
        "GODOT_PATH": "<ABSOLUTE_PATH_TO_GODOT_EXECUTABLE>"
      }
    }
  }
}
```

Replace the placeholders with your actual paths. Example on Windows:

```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["D:/Workspace/mcps/godot-mcp/build/index.js"],
      "env": {
        "GODOT_PATH": "D:/Games/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe"
      }
    }
  }
}
```

**Important:** Use forward slashes in paths, even on Windows. This avoids escape character issues in JSON.

---

## Step 5: Organize Your Sprite Sheets

Create a clean asset directory structure and place your downloaded sprites:

```
my-game/
  assets/
    sprites/
      player/
        player_idle.png
        player_walk.png
      enemies/
        slime_idle.png
        slime_walk.png
      ui/
        hearts.png
      npc/
        npc_knight.png
    tilesets/
    audio/
      sfx/
      music/
    fonts/
  scenes/
  scripts/
  project.godot
  .mcp.json
```

---

## Step 6: Import Assets into Godot

After placing sprite files in the `assets/` folder, Godot needs to generate `.import` sidecar files before the MCP can reference them. Run:

```bash
# Replace with your actual Godot path
"/path/to/godot" --headless --import --path .
```

The `--path .` tells Godot to use the current directory as the project root. This command:
- Scans for new asset files
- Generates `.import` files alongside each asset
- Generates `.uid` files (Godot 4.4+)
- Exits when done

**You must run this every time you add new asset files.** The MCP's `load_sprite` tool will fail if the asset has not been imported first.

---

## Step 7: Set Up `.gitignore`

Create a `.gitignore` appropriate for Godot:

```gitignore
# Godot 4.x ignores
.godot/

# OS files
.DS_Store
Thumbs.db

# MCP config (contains local paths)
.mcp.json
```

**Do NOT ignore these** -- they must be committed:
- `*.uid` files (required by Godot 4.4+, not regenerable consistently)
- `*.import` files (not reliably regenerable across machines)

---

## Step 8: Start Claude Code

Launch Claude Code from your project root:

```bash
cd ~/games/my-game
claude
```

Claude Code will detect the `.mcp.json` and start the godot-mcp server automatically. You should see the MCP tools become available.

---

## Step 9: Verify the MCP Connection

Ask Claude Code to check the connection:

> "Get the Godot version and project info to confirm MCP is working."

This will call `get_godot_version` and `get_project_info`. If both return valid data, your setup is complete.

---

## The Development Workflow

With everything set up, here is the pattern you will follow when building with Claude Code + godot-mcp:

### What the MCP Can Do
- **create_scene** -- create new `.tscn` scene files
- **add_node** -- add child nodes to existing scenes
- **load_sprite** -- assign a texture to a Sprite2D node
- **run_project / stop_project** -- launch and stop the game
- **get_debug_output** -- capture print statements and errors from the running game
- **save_scene** -- save changes to a scene
- **get_project_info** -- inspect project structure
- **launch_editor** -- open the Godot editor

### What the MCP Cannot Do (Claude Code fills the gap)
- **Create GDScript files** -- use Claude Code's Write tool
- **Create `project.godot`** -- use Claude Code's Write tool
- **Attach scripts to nodes** -- use Claude Code's Edit tool on the `.tscn` file
- **Set Vector2, Color, or complex properties** -- set these in `.tscn` files directly or in `_ready()`
- **Instance sub-scenes** -- edit the `.tscn` file directly

### Typical Build Cycle

```
1. Write tool    --> project.godot (if not created yet)
2. Bash          --> godot --headless --import (after adding new assets)
3. MCP           --> create_scene + add_node + load_sprite (build scene tree)
4. Write tool    --> .gd scripts (game logic)
5. Edit tool     --> .tscn files (attach scripts, set complex properties)
6. MCP           --> run_project (test it)
7. MCP           --> get_debug_output (check for errors)
8. MCP           --> stop_project (stop the game)
9. Iterate       --> Edit scripts/scenes, re-run
```

---

## Tips and Gotchas

1. **Always run `godot --headless --import` after adding new asset files.** The MCP cannot use assets that Godot has not imported yet.

2. **Use Area2D for damage detection, not body-to-body collision.** CharacterBody2D collisions cause pushing/sliding. Use the hitbox/hurtbox pattern with Area2D nodes instead.

3. **Supplement `area_entered` with periodic overlap checks.** The `area_entered` signal only fires once when two areas first overlap. For continuous contact damage (like a slime sitting on the player), also poll `get_overlapping_areas()` on a timer.

4. **Set complex properties in code or `.tscn`, not via MCP.** The `add_node` tool drops Vector2, Color, and other complex property types silently. Set them in your `_ready()` function or edit the `.tscn` file directly.

5. **Commit `.uid` and `.import` files to git.** These are required for the project to work on other machines.

6. **Keep `.mcp.json` out of git.** It contains absolute paths specific to your machine. Create a `.mcp.json.example` with placeholder paths for others to reference.

7. **For pixel art, use Nearest filtering.** Set `rendering/textures/canvas_textures/default_texture_filter=0` in `project.godot` to avoid blurry sprites.

8. **Normalize animation speed by cycle duration, not per-frame delay.** Different sprite sheets have different frame counts. Define a total cycle duration (e.g., 0.6 seconds) and divide by frame count to get the per-frame delay. This keeps animations visually consistent regardless of frame count.

---

## Quick Reference: Input Map Setup

If your game needs input actions (movement, attack, interact), add them to `project.godot` under `[input]`:

```ini
[input]

move_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":119,"location":0,"echo":false,"script":null)]
}
move_down={...}
move_left={...}
move_right={...}
attack={...}
interact={...}
```

This is verbose in raw format. It is often easier to open the Godot editor (`launch_editor` via MCP), set up inputs in the UI, save, and then continue headlessly.

---

You are now ready to start building. Tell Claude Code what game you want to make, describe your sprites, and start the build cycle.
