# 2D Platformer — Quick Start Guide

## Prerequisites

- Godot Engine 4.x (download from [godotengine.org](https://godotengine.org/download))
- Claude Code (requires Anthropic account)
- Node.js 18+ (for Godot MCP)
- godot-mcp (install from [github.com/Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp))

## Step 1: Create a New Godot Project

1. Open Godot Engine — the **Project Manager** opens
2. Click **"New Project"**
3. **Project Name:** enter your game name (e.g., `pixel-jump`)
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
| Viewport Width | Display > Window > Size > Viewport Width | `640` |
| Viewport Height | Display > Window > Size > Viewport Height | `360` |
| Window Width Override | Display > Window > Size > Window Width Override | `1280` |
| Window Height Override | Display > Window > Size > Window Height Override | `720` |
| Stretch Mode | Display > Window > Stretch > Mode | `viewport` |
| Stretch Aspect | Display > Window > Stretch > Aspect | `keep` |
| Scale Mode | Display > Window > Stretch > Scale Mode | `integer` |

> **Why 640x360?** The most popular choice for 2D pixel art. Wider viewport gives horizontal visibility for platforming jumps. Scales cleanly to 1280x720 (2x), 1920x1080 (3x), and 3840x2160 (6x).

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
| `move_left` | A, Left Arrow | Move left |
| `move_right` | D, Right Arrow | Move right |
| `jump` | Space, W, Up Arrow | Jump (hold for variable height) |
| `attack` | J, Z | Melee attack |
| `dash` | Shift, K | Dash/dodge |
| `interact` | E, X, Enter | Interact with objects |
| `pause` | Escape, P | Pause menu |

> **Note:** No `move_up`/`move_down` unless you plan ladders or climbing. Easy to add later.

### Physics

Navigate to **Physics > 2D** in the left panel.

| Setting | Path | Value |
|---------|------|-------|
| Default Gravity | Physics > 2D > Default Gravity | `980` (default — keep it) |

> **Gravity tuning:** 980 is Earth-like and a good starting point. For floaty jumps (Celeste-style), try 600-800. For heavy/snappy jumps, try 1500-2500. Tune iteratively with your sprite size and jump velocity.

### Collision Layers

Navigate to **Layer Names > 2D Physics** in the left panel. Enter a name for each layer:

| Layer # | Name | Used By |
|---------|------|---------|
| 1 | World | Platforms, walls, floor tilemap |
| 2 | Player | Player CharacterBody2D |
| 3 | Enemies | Enemy bodies |
| 4 | PlayerHurtbox | Player damage detection |
| 5 | EnemyHurtbox | Enemy damage detection |
| 6 | PlayerHitbox | Player attack area |
| 7 | Hazards | Spikes, lava, saw blades |
| 8 | Collectibles | Coins, gems, power-ups |
| 9 | OneWayPlatforms | Platforms you can jump through from below |
| 10 | Triggers | Checkpoints, level end, cutscene triggers |

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
│   │   ├── items/
│   │   └── tilesets/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   └── fonts/
```

> After adding new asset files, run `godot --headless --import` before using them with Godot MCP.

## Step 5: Start Building!

Tell Claude: **"Let's build a platformer called Pixel Jump!"**

Claude will use the CLAUDE.md context and Godot MCP to create scenes, add sprites, write GDScript, and iterate with you in real time.
