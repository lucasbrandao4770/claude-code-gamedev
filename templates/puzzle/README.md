# 2D Puzzle Game — Quick Start Guide

## Prerequisites

- Godot Engine 4.x (download from [godotengine.org](https://godotengine.org/download))
- Claude Code (requires Anthropic account)
- Node.js 18+ (for Godot MCP)
- godot-mcp (install from [github.com/Coding-Solo/godot-mcp](https://github.com/Coding-Solo/godot-mcp))

## Step 1: Create a New Godot Project

1. Open Godot Engine — the **Project Manager** opens
2. Click **"New Project"**
3. **Project Name:** enter your game name (e.g., `block-shift`)
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
| Stretch Aspect | Display > Window > Stretch > Aspect | `keep` |
| Scale Mode | Display > Window > Stretch > Scale Mode | `integer` |

> **Why `canvas_items`?** Puzzle games are UI-heavy — instructions, scores, move counters, and level indicators need crisp, readable text. `canvas_items` renders text at full resolution while keeping sprites pixel-perfect. Use `expand` for Stretch Aspect instead of `keep` if you want responsive layout without black bars.

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
| `select` | Left Mouse Button | Select / place piece |
| `cancel` | Right Mouse Button, Escape | Cancel / deselect |
| `undo` | Ctrl+Z, Z | Undo last move |
| `redo` | Ctrl+Y, Shift+Z | Redo last undo |
| `rotate_cw` | R, E | Rotate piece clockwise |
| `rotate_ccw` | Shift+R, Q | Rotate piece counter-clockwise |
| `pause` | Escape, P | Pause menu |
| `hint` | H | Show hint |
| `restart` | Ctrl+R | Restart current puzzle |
| `move_up` | W, Up Arrow | Grid navigation (keyboard) |
| `move_down` | S, Down Arrow | Grid navigation |
| `move_left` | A, Left Arrow | Grid navigation |
| `move_right` | D, Right Arrow | Grid navigation |

> **Note:** Puzzle games vary widely in input needs. A Tetris clone needs rotate + move. A point-and-click puzzle only needs mouse. Customize these actions to your specific puzzle type.

### Physics

Navigate to **Physics > 2D** in the left panel.

| Setting | Path | Value |
|---------|------|-------|
| Default Gravity | Physics > 2D > Default Gravity | `0` |

> **Note:** Set gravity to 0 unless you are building a physics-based puzzle (like Angry Birds). For grid-based puzzles, gravity is handled in game logic, not the physics engine.

### Collision Layers

Navigate to **Layer Names > 2D Physics** in the left panel. Enter a name for each layer:

| Layer # | Name | Used By |
|---------|------|---------|
| 1 | World | Grid boundaries |
| 2 | Pieces | Puzzle pieces / blocks |
| 3 | Targets | Goal positions / slots |
| 4 | Clickable | Clickable areas (Area2D for mouse detection) |

> **Note:** Many puzzle games use `_input_event` on Area2D nodes or raycasting rather than physics collision. You may not need all of these layers depending on your puzzle type.

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
│   │   ├── pieces/
│   │   ├── backgrounds/
│   │   └── effects/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── ui/
│   └── fonts/
```

> After adding new asset files, run `godot --headless --import` before using them with Godot MCP.

## Step 5: Start Building!

Tell Claude: **"Let's build a puzzle game called Block Shift!"**

Claude will use the CLAUDE.md context and Godot MCP to create scenes, add sprites, write GDScript, and iterate with you in real time.
