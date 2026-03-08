# Top-Down Zelda-like RPG — Quick Start Guide

## Prerequisites

- Godot Engine 4.x (download from [godotengine.org](https://godotengine.org/download))
- Claude Code (requires Anthropic account)
- Node.js 18+ (for Godot MCP)
- godot-mcp (install from [github.com/Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp))

## Step 1: Create a New Godot Project

1. Open Godot Engine — the **Project Manager** opens
2. Click **"New Project"**
3. **Project Name:** enter your game name (e.g., `forge-of-worlds`)
4. **Project Path:** choose or create the folder where the project will live
5. **Renderer:** select **Compatibility** (best for 2D pixel art — lowest overhead, broadest hardware support, web export ready)
6. **Version Control Metadata:** select **Git**
7. Click **"Create & Edit"** — the editor opens with your empty project

## Step 2: Configure Project Settings

Open **Project > Project Settings** from the top menu bar.

### Display

Navigate to **Display > Window** in the left panel.

| Setting | Path | Value |
|---------|------|-------|
| Viewport Width | Display > Window > Size > Viewport Width | `320` |
| Viewport Height | Display > Window > Size > Viewport Height | `180` |
| Window Width Override | Display > Window > Size > Window Width Override | `1280` |
| Window Height Override | Display > Window > Size > Window Height Override | `720` |
| Stretch Mode | Display > Window > Stretch > Mode | `viewport` |
| Stretch Aspect | Display > Window > Stretch > Aspect | `keep` |
| Scale Mode | Display > Window > Stretch > Scale Mode | `integer` |

> **Why 320x180?** This gives an authentic retro feel for top-down RPGs. With 48x48 character sprites, the player occupies a meaningful portion of the screen. The window override of 1280x720 scales it 4x cleanly.

### Rendering

Navigate to **Rendering > Textures** in the left panel.

| Setting | Path | Value |
|---------|------|-------|
| Default Texture Filter | Rendering > Textures > Canvas Textures > Default Texture Filter | `Nearest` |

> **CRITICAL:** This is the most important setting for pixel art. Without it, all sprites look blurry.

Navigate to **Rendering > 2D** in the left panel.

| Setting | Path | Value |
|---------|------|-------|
| Snap 2D Transforms to Pixel | Rendering > 2D > Snap 2D Transforms to Pixel | `true` (checked) |
| Snap 2D Vertices to Pixel | Rendering > 2D > Snap 2D Vertices to Pixel | `true` (checked) |

### Input Map

Click the **Input Map** tab at the top of Project Settings. For each action below: type the action name in the **"Add New Action"** field, click **Add**, then click the **"+"** button next to it to assign keys.

| Action Name | Keyboard Keys | Description |
|-------------|---------------|-------------|
| `move_up` | W, Up Arrow | Move up |
| `move_down` | S, Down Arrow | Move down |
| `move_left` | A, Left Arrow | Move left |
| `move_right` | D, Right Arrow | Move right |
| `attack` | J, Z, Space | Sword/weapon attack |
| `interact` | K, X, Enter | Talk to NPCs, open chests |
| `inventory` | I, Tab | Open inventory/menu |
| `pause` | Escape, P | Pause menu |

> **Tip:** Always map both WASD and Arrow Keys to movement. It costs nothing and supports both player preferences.

### Physics

Navigate to **Physics > 2D** in the left panel.

| Setting | Path | Value |
|---------|------|-------|
| Default Gravity | Physics > 2D > Default Gravity | `0` |

> **Important:** Top-down games have no gravity. The default value (980) is for side-view games. Set it to 0.

### Collision Layers

Navigate to **Layer Names > 2D Physics** in the left panel. Enter a name for each layer:

| Layer # | Name | Used By |
|---------|------|---------|
| 1 | World | TileMap collision, walls, obstacles |
| 2 | Player | Player CharacterBody2D |
| 3 | Enemies | Enemy CharacterBody2D |
| 4 | PlayerHurtbox | Player Area2D for receiving damage |
| 5 | EnemyHurtbox | Enemy Area2D for receiving damage |
| 6 | PlayerHitbox | Sword swing Area2D |
| 7 | EnemyHitbox | Enemy attack Area2D |
| 8 | Collectibles | Hearts, rupees, items |
| 9 | Interactables | NPCs, signs, chests, doors |
| 10 | Triggers | Room transitions, cutscene triggers |

## Step 3: Set Up Claude Code

1. Copy `CLAUDE.md` from this template to your project root
2. Copy `.mcp.json.example` to `.mcp.json` and edit the `godotPath` with your local Godot executable path
3. Copy the `.claude/skills/` folder from the repo root to your project
4. Open a terminal in your project folder and run: `claude`

## Step 4: Download Assets

See `ASSET-SOURCES.md` for curated free asset packs. Download and organize into:

```
your-project/
├── assets/
│   ├── sprites/
│   │   ├── player/
│   │   ├── enemies/
│   │   ├── npcs/
│   │   ├── items/
│   │   └── tilesets/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   └── fonts/
```

> After adding new asset files, run `godot --headless --import` before using them with Godot MCP.

## Step 5: Start Building!

Tell Claude: **"Let's build a Zelda-like RPG called Forge of Worlds!"**

Claude will use the CLAUDE.md context and Godot MCP to create scenes, add sprites, write GDScript, and iterate with you in real time.
