# Setting Up a Fresh Godot 4.x Project with godot-mcp

Here is a complete walkthrough for going from zero to a working Claude Code + Godot MCP workflow with your sprite sheets ready to use.

---

## Prerequisites

Before we start, make sure you have:

- **Godot 4.x** installed (Steam, standalone, or Scoop -- any install method works)
- **Node.js** (v18+) installed -- the MCP server runs on Node
- **Claude Code** CLI installed and working
- Your sprite sheets downloaded and ready to place

---

## Step 1: Clone and Build godot-mcp

The MCP server is the bridge between Claude Code and the Godot engine. Clone it and build it once:

```bash
# Pick a location for MCP servers (outside your game project)
cd D:/Workspace/mcps
git clone https://github.com/Coding-Solo/godot-mcp.git
cd godot-mcp
npm install
npm run build
```

After this, the built server lives at `D:/Workspace/mcps/godot-mcp/build/index.js`. You will reference this path in your project configuration.

---

## Step 2: Find Your Godot Executable Path

You need the full path to your Godot binary. Common locations:

| Install Method | Typical Path |
|---|---|
| Steam | `D:/Games/Steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe` |
| Standalone (Windows) | `C:/Godot/Godot_v4.x-stable_win64.exe` |
| Scoop | `C:/Users/<you>/scoop/apps/godot/current/godot.exe` |
| Linux | `/usr/bin/godot` or `~/.local/bin/godot` |
| macOS | `/Applications/Godot.app/Contents/MacOS/Godot` |

Note: Steam names the Godot 4.x binary `godot.windows.opt.tools.64.exe` -- this is not an old version indicator, it is the correct binary for Godot 4.x on Steam.

Test it works by running:

```bash
"/path/to/your/godot" --version
```

You should see something like `4.6.1.stable`.

---

## Step 3: Create Your Project Folder and Structure

Create a new folder for your game project and set up the directory structure:

```bash
mkdir -p my-game-project
cd my-game-project

# Create the folder structure
mkdir -p assets/sprites/player
mkdir -p assets/sprites/enemies
mkdir -p assets/sprites/items
mkdir -p assets/sprites/ui
mkdir -p assets/tilesets
mkdir -p assets/audio/sfx
mkdir -p assets/audio/music
mkdir -p assets/fonts
mkdir -p scenes/player
mkdir -p scenes/enemies
mkdir -p scenes/pickups
mkdir -p scenes/ui
mkdir -p scenes/world
mkdir -p scripts/player
mkdir -p scripts/enemies
mkdir -p scripts/components
mkdir -p scripts/autoloads
mkdir -p resources
```

---

## Step 4: Create `project.godot`

Every Godot project needs a `project.godot` file at its root. This file defines the project name, window settings, input mappings, collision layers, and rendering configuration.

Create `project.godot` in your project root with at minimum:

```ini
config_version=5

[application]

config/name="My Game"
config/features=PackedStringArray("4.6")

[display]

window/size/viewport_width=640
window/size/viewport_height=360
window/size/window_width_override=1280
window/size/window_height_override=720
window/stretch/mode="viewport"

[rendering]

textures/canvas_textures/default_texture_filter=0
```

Key settings explained:
- **Viewport 640x360 with 1280x720 window**: gives you a nice 2x pixel-perfect scale for 16-bit style games
- **Stretch mode "viewport"**: pixel art stays crisp at any window size
- **`default_texture_filter=0`**: sets Nearest filtering globally so pixel art does not get blurry

You will likely want to add input mappings (WASD, attack, interact) and collision layer names. If you are building a top-down RPG, you can copy these sections from one of the templates in this repo (e.g., `templates/zelda-like-rpg/project.godot`) which has WASD + arrow keys, attack (Space), interact (E), and named collision layers already configured.

---

## Step 5: Place Your Sprite Sheets

Copy your downloaded sprite sheets into the `assets/` folders:

```
assets/
  sprites/
    player/
      idle.png
      walk.png
      attack.png
    enemies/
      slime_idle.png
      slime_walk.png
    ui/
      hearts.png
```

**Important:** After placing new assets, you MUST run the headless import before MCP can use them. This is the number one source of failures -- Godot does not recognize files on disk as resources until they have been imported.

```bash
"/path/to/your/godot" --headless --path "/path/to/my-game-project" --import
```

This generates `.import` sidecar files next to each asset. These files (along with `.uid` files) should be committed to git.

---

## Step 6: Configure MCP for Your Project

Create a `.mcp.json` file in your project root. This tells Claude Code how to launch the godot-mcp server:

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

Replace both paths with your actual paths:
- `args` -- the path to the built `index.js` from Step 1
- `GODOT_PATH` -- the path to your Godot executable from Step 2

**Do not commit `.mcp.json` to git** -- it contains machine-specific paths. Instead, create a `.mcp.json.example` with placeholder paths and add `.mcp.json` to your `.gitignore`:

```json
{
  "mcpServers": {
    "godot": {
      "command": "node",
      "args": ["<PATH_TO_GODOT_MCP>/build/index.js"],
      "env": {
        "GODOT_PATH": "<PATH_TO_GODOT_EXECUTABLE>"
      }
    }
  }
}
```

---

## Step 7: Verify MCP Connectivity

Start Claude Code from your project directory:

```bash
cd my-game-project
claude
```

Then ask Claude to verify the MCP connection by calling `get_godot_version`. If the MCP is configured correctly, it will return your Godot version (e.g., `v4.6.1.stable`). If this fails, double-check your paths in `.mcp.json`.

You can also call `get_project_info` with your project path to confirm the MCP can see your project and its assets.

---

## Step 8: Set Up Git (Recommended)

Initialize git and configure it for Godot:

```bash
cd my-game-project
git init
```

Create a `.gitignore` appropriate for Godot:

```
# Godot 4.x ignores
.godot/
*.tmp
*.log

# MCP config (machine-specific paths)
.mcp.json

# OS files
.DS_Store
Thumbs.db
```

**Critical:** Do NOT ignore these files -- they must be committed:
- `.uid` files (Godot 4.4+ requirement for stable resource references)
- `.import` files (not reliably regenerated across machines)

---

## The Workflow: How MCP and Claude Code Work Together

With everything set up, here is the workflow sequence you will follow. Each step uses the right tool for the job, because MCP and Claude Code each have things they can and cannot do.

```
 1. Write tool    --> project.godot (already done in Step 4)
 2. Place assets  --> copy sprites, audio, fonts into assets/ folders
 3. Bash          --> godot --headless --path <project> --import
 4. MCP           --> create_scene (one per entity: player, enemy, HUD, world)
 5. MCP           --> add_node (build node trees: Sprite2D, CollisionShape2D, etc.)
 6. MCP           --> load_sprite (assign textures to Sprite2D nodes)
 7. Write tool    --> create .gd scripts (MCP cannot create GDScript files)
 8. Edit tool     --> patch .tscn files (attach scripts, set Vector2 properties, add sub-resources)
 9. MCP           --> run_project (launches the game)
10. MCP           --> get_debug_output (read errors and print statements)
11. MCP           --> stop_project (clean shutdown)
12. Fix           --> edit scripts or scenes, then repeat from step 9
```

### What MCP Can Do

- Create scenes with any root node type (`create_scene`)
- Add nodes to scene trees with simple properties like strings, integers, booleans (`add_node`)
- Load sprite textures onto Sprite2D nodes (`load_sprite`)
- Save/duplicate scenes (`save_scene`)
- Run the game, capture debug output, and stop it (`run_project`, `get_debug_output`, `stop_project`)
- Launch the Godot editor (`launch_editor`)

### What MCP Cannot Do (Use Claude Code's Write/Edit Tools Instead)

- **Create GDScript files** -- use the Write tool
- **Create or modify project.godot** -- use the Write tool
- **Attach scripts to scene nodes** -- edit the `.tscn` file to add `[ext_resource]` and `script = ExtResource("id")` entries
- **Set Vector2, Color, Rect2, or other complex properties** -- these are silently dropped by `add_node`; set them in the `.tscn` file directly or in `_ready()`
- **Define collision shapes** -- add `[sub_resource type="CircleShape2D"]` blocks in the `.tscn` file
- **Instance sub-scenes** -- use `preload().instantiate()` in GDScript

---

## Quick Sanity Check

Before you start building, verify everything is ready:

1. Run `get_godot_version` via MCP -- confirms MCP server is connected
2. Run `get_project_info` via MCP -- confirms your project is detected and shows asset counts
3. Run `godot --headless --path <project> --import` -- confirms assets are imported (look for `.import` files next to your sprites)

If all three pass, you are ready to start building scenes. Ask Claude to create your first scene (e.g., a player CharacterBody2D with Sprite2D, CollisionShape2D, and Camera2D), and the MCP workflow will take it from there.

---

## Common Gotchas

| Problem | Cause | Fix |
|---|---|---|
| `load_sprite` returns "No loader found for resource" | Assets not imported | Run `godot --headless --path <project> --import` |
| Vector2 properties (position, scale) are ignored | MCP silently drops complex types | Set them in the `.tscn` file or in `_ready()` |
| Script not attached to node | MCP cannot attach scripts | Edit the `.tscn` to add `[ext_resource]` + `script = ExtResource(...)` |
| Collision shapes missing | MCP cannot create sub-resources | Add `[sub_resource type="RectangleShape2D"]` blocks in the `.tscn` |
| `update_project_uids` fails | Known bug: double-prefixes `res://` | Do not use this tool; manage UIDs manually or via the editor |
| Pixel art looks blurry | Wrong texture filter | Set `default_texture_filter=0` in project.godot `[rendering]` section |
