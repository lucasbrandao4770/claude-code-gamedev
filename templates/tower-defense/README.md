# 2D Tower Defense — Quick Start Guide

## Prerequisites

- Godot Engine 4.x (download from [godotengine.org](https://godotengine.org/download))
- Claude Code (requires Anthropic account)
- Node.js 18+ (for Godot MCP)
- godot-mcp (install from [github.com/Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp))

## Step 1: Create a New Godot Project

1. Open Godot Engine — the **Project Manager** opens
2. Click **"New Project"**
3. **Project Name:** enter your game name (e.g., `tower-siege`)
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
| Stretch Mode | Display > Window > Stretch > Mode | `canvas_items` |
| Stretch Aspect | Display > Window > Stretch > Aspect | `expand` |
| Scale Mode | Display > Window > Stretch > Scale Mode | `fractional` |

> **Why `canvas_items` instead of `viewport`?** Tower defense is UI-heavy — players constantly read tower stats, wave info, and resource counts. `canvas_items` renders text at full resolution for readability while keeping sprites pixel-perfect. `viewport` would make small UI text pixelated and hard to read.

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
| `select` | Left Mouse Button | Select tile / place tower |
| `cancel` | Right Mouse Button, Escape | Cancel placement / deselect |
| `pause` | P, Space | Pause game |
| `speed_up` | F, Tab | Fast-forward waves |
| `speed_normal` | G | Return to normal speed |
| `tower_1` | 1 | Quick-select tower type 1 |
| `tower_2` | 2 | Quick-select tower type 2 |
| `tower_3` | 3 | Quick-select tower type 3 |
| `tower_4` | 4 | Quick-select tower type 4 |
| `upgrade` | U, E | Upgrade selected tower |
| `sell` | S, Delete | Sell selected tower |

> **Note:** Tower defense is primarily mouse-driven. Keyboard shortcuts are for power users and speed.

### Physics

Navigate to **Physics > 2D** in the left panel.

| Setting | Path | Value |
|---------|------|-------|
| Default Gravity | Physics > 2D > Default Gravity | `0` |

> **Important:** Tower defense uses a top-down or isometric view — no gravity needed. Set it to 0.

### Collision Layers

Navigate to **Layer Names > 2D Physics** in the left panel. Enter a name for each layer:

| Layer # | Name | Used By |
|---------|------|---------|
| 1 | World | Map boundaries, non-placeable areas |
| 2 | Path | Enemy walk path (for pathfinding) |
| 3 | Enemies | Enemy bodies |
| 4 | Towers | Placed tower collision (prevent overlapping) |
| 5 | TowerRange | Tower detection radius (Area2D) |
| 6 | Projectiles | Tower projectiles |
| 7 | PlacementGrid | Valid placement zones |

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
│   │   ├── towers/
│   │   ├── enemies/
│   │   ├── projectiles/
│   │   └── tilesets/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── ui/
│   └── fonts/
```

> After adding new asset files, run `godot --headless --import` before using them with Godot MCP.

## Step 5: Start Building!

Tell Claude: **"Let's build a tower defense game called Tower Siege!"**

Claude will use the CLAUDE.md context and Godot MCP to create scenes, add sprites, write GDScript, and iterate with you in real time.
