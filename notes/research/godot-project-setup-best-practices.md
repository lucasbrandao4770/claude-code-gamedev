# Godot 4.x Project Setup Best Practices for 2D Pixel Art Games

> **Research Date:** 2026-03-08
> **Godot Versions Covered:** 4.3 – 4.6 (stable)
> **Purpose:** Reference for game project template READMEs (zelda-like-rpg, platformer, tower-defense, puzzle)

---

## Table of Contents

1. [Creating a New Project](#1-creating-a-new-project)
2. [Universal Setup — All 2D Pixel Art Genres](#2-universal-setup--all-2d-pixel-art-genres)
   - 2.1 Renderer Selection
   - 2.2 Display / Window Settings
   - 2.3 Texture Filtering
   - 2.4 Pixel Snapping
   - 2.5 Import Defaults
   - 2.6 Collision Layer Naming
   - 2.7 Autoloads (Singletons)
   - 2.8 Version Control
3. [Genre-Specific Setup](#3-genre-specific-setup)
   - 3.1 Top-Down RPG (Zelda-like)
   - 3.2 Platformer
   - 3.3 Tower Defense
   - 3.4 Puzzle
4. [Common Mistakes to Avoid](#4-common-mistakes-to-avoid)
5. [Sources](#5-sources)

---

## 1. Creating a New Project

### Step-by-Step: New Project Wizard

1. **Launch Godot Engine** — the Project Manager opens.
2. Click **"New Project"** (or `+ New` in some versions).
3. **Project Name** — enter the project name (e.g., `zelda-like-rpg`).
4. **Project Path** — choose or create the folder where the project will live. Godot creates a `project.godot` file here.
5. **Renderer** — select one of three options (see section 2.1 below). For 2D pixel art, choose **Compatibility**.
6. **Version Control Metadata** — select **Git** (creates a default `.gitignore`). Select **None** if you will set up Git manually.
7. Click **"Create & Edit"** — the editor opens with your empty project.

> **What the user should see:** A dialog with fields for Project Name, Project Path (with a Browse button), a Renderer dropdown (Forward+, Mobile, Compatibility), and a Version Control Metadata dropdown (Git, None).

### What the Wizard Creates

- `project.godot` — INI-format text file with all project settings. Can be edited manually, but the Project Settings window is recommended.
- `.godot/` folder — editor cache, imported resources. **Always exclude from version control.**
- `.gitignore` (if Git was selected) — pre-configured to exclude `.godot/` and other generated files.

### Key Principle: Always Create Projects in the Godot Editor

The `project.godot` file *can* be written by hand, but this is fragile and error-prone. The editor:
- Generates correct syntax and default values
- Creates the `.godot/` import cache automatically
- Validates settings in real time
- Handles platform-specific defaults

**Recommendation for templates:** Instruct users to create the project in Godot first, then clone/copy template files into the project folder.

---

## 2. Universal Setup — All 2D Pixel Art Genres

These settings apply to **every** 2D pixel art project, regardless of genre.

### 2.1 Renderer Selection

Godot 4.x offers three renderers:

| Renderer | API | Best For | 2D Pixel Art? |
|----------|-----|----------|---------------|
| **Forward+** | Vulkan (RenderingDevice) | Desktop 3D, advanced effects | Overkill for 2D |
| **Mobile** | Vulkan (RenderingDevice) | Mobile 3D, desktop VR | Works for 2D but unnecessary |
| **Compatibility** | OpenGL 3.3 / OpenGL ES 3.0 / WebGL 2.0 | 2D games, low-end hardware, web export | **Recommended** |

**Why Compatibility for 2D pixel art:**
- Lowest overhead — 2D pixel art does not need Vulkan features
- Broadest hardware support (older GPUs, integrated graphics)
- **Only renderer that supports web export** (WebGL 2.0)
- Perfectly sufficient for all 2D rendering features (shaders, particles, lights)
- Fastest startup time and lowest memory usage

**When to consider Forward+:** Only if you need compute shaders, advanced post-processing, or 3D elements mixed with 2D. For pure 2D pixel art, Compatibility is the correct choice.

**Note:** The renderer can be changed later in Project Settings > Rendering > Renderer, but switching between Compatibility and Forward+/Mobile may require adjusting materials and shaders.

### 2.2 Display / Window Settings

**Path:** Project > Project Settings > Display > Window

#### Viewport Size (Base Resolution)

This is the **internal rendering resolution** — how many pixels your game world "sees." For pixel art, this should be small.

| Resolution | Aspect Ratio | Scale to 1080p | Scale to 1440p | Scale to 4K | Best For |
|------------|-------------|----------------|----------------|-------------|----------|
| **320×180** | 16:9 | 6× | 8× | 12× | Very low-res retro (NES/GB feel) |
| **384×216** | 16:9 | 5× | 6.67× | 10× | Small sprites, classic feel |
| **426×240** | 16:9 (approx) | 4.5× | 6× | 9× | GDQuest recommended |
| **640×360** | 16:9 | 3× | 4× | 6× | **Most popular choice** — good balance |
| **256×144** | 16:9 | 7.5× | 10× | 15× | Ultra low-res, Game Boy style |

**Recommended default:** **640×360** or **320×180**

- 640×360 is the most commonly used. It scales cleanly to 1280×720 (2×), 1920×1080 (3×), 2560×1440 (4×), and 3840×2160 (6×).
- 320×180 gives a more authentic retro look but limits how much you can show on screen.

**How to choose:** Your base resolution should make your main character sprite roughly 1/10 to 1/15 of the viewport height. If your character is 16px tall, 320×180 gives ~11 character-heights. If 32px tall, 640×360 gives ~11 character-heights.

**Settings to configure:**

| Setting | Path | Value |
|---------|------|-------|
| Viewport Width | Display > Window > Size > Viewport Width | `640` (or `320`) |
| Viewport Height | Display > Window > Size > Viewport Height | `360` (or `180`) |
| Window Width Override | Display > Window > Size > Window Width Override | `1280` (or `1920`) |
| Window Height Override | Display > Window > Size > Window Height Override | `720` (or `1080`) |
| Resizable | Display > Window > Size > Resizable | `true` |
| Mode | Display > Window > Size > Mode | `Windowed` |

> **Window Width/Height Override** sets the actual window size when running the game. This should be an integer multiple of the viewport size for clean scaling.

#### Stretch Settings

| Setting | Path | Value | Why |
|---------|------|-------|-----|
| **Stretch Mode** | Display > Window > Stretch > Mode | `viewport` | Renders at base resolution, then scales up. Authentic pixel look. |
| **Stretch Aspect** | Display > Window > Stretch > Aspect | `keep` | Maintains aspect ratio, adds black bars if needed. |
| **Scale Mode** | Display > Window > Stretch > Scale Mode | `integer` | Scales by whole numbers only (2×, 3×, 4×). Prevents uneven pixels. Available since Godot 4.3. |

**Stretch Mode comparison:**

| Mode | Behavior | Best For |
|------|----------|----------|
| `disabled` | No scaling, game renders at window resolution | Not for pixel art |
| `canvas_items` | Renders at window resolution, uses viewport size as reference. Sprites are pixel-perfect, but camera moves smoothly. Fonts render at full resolution (crisp text). | Pixel art games with lots of UI text |
| `viewport` | Renders at viewport resolution, then scales entire image up. **True low-res look.** Everything including text is pixelated. | **Pure pixel art games** (recommended default) |

**When to use `canvas_items` instead of `viewport`:**
- If your game is UI-heavy and you need crisp, readable text at high resolution
- If you want smooth camera movement (no pixel snapping on camera)
- If you use tweens or particle effects that look better at high resolution
- Trade-off: sprites still look pixel-perfect, but the "retro" feel is reduced

### 2.3 Texture Filtering

**Path:** Project > Project Settings > Rendering > Textures > Canvas Textures

| Setting | Value | Why |
|---------|-------|-----|
| **Default Texture Filter** | `Nearest` | Nearest-neighbor interpolation. Preserves hard pixel edges. Without this, pixel art looks blurry when scaled. |

> **CRITICAL:** This is the single most important setting for pixel art. The default is `Linear`, which smooths/blurs textures. You **must** change it to `Nearest`.

**Per-node override:** Individual CanvasItem nodes can override the texture filter via the `Texture Filter` property in the Inspector (set to `Nearest` or `Inherit` to use project default).

**For fonts:** Pixel art fonts must also use Nearest filtering. Set font sizes to integer multiples of the design size to avoid blurriness.

### 2.4 Pixel Snapping

**Path:** Project > Project Settings > Rendering > 2D

| Setting | Path | Value | Why |
|---------|------|-------|-----|
| **Snap 2D Transforms to Pixel** | Rendering > 2D > Snap 2D Transforms to Pixel | `true` | Forces all Node2D positions to snap to whole pixels. Eliminates the "shimmering" effect when sprites sit between two pixels during movement. |
| **Snap 2D Vertices to Pixel** | Rendering > 2D > Snap 2D Vertices to Pixel | `true` | Snaps polygon/line vertices to pixels. Prevents sub-pixel rendering artifacts on shapes. |

> **Note:** Enabling pixel snapping makes movement slightly less smooth (stepping in whole pixels). For games where smooth movement matters more than pixel-perfect rendering, you can leave these off and rely on `viewport` stretch mode instead.

> **Camera2D consideration:** If using Camera2D with Position Smoothing, pixel snapping can cause slight jitter. Either disable smoothing or accept the trade-off. Keep camera zoom at whole numbers (1×, 2×, 3×) to avoid uneven pixel scaling.

### 2.5 Import Defaults

#### Setting Project-Wide Import Defaults

**Path:** Project > Project Settings > Import Defaults (tab at top)

This tab lets you configure default import settings for each resource type. When you add new files, they will use these defaults automatically.

**For Texture2D:**

| Import Setting | Value | Why |
|----------------|-------|-----|
| Compress > Mode | `Lossless` | Never use Lossy for pixel art — it introduces artifacts |
| Filter | `false` (Off) | Or leave as "Project Default" if global filter is Nearest |
| Mipmaps > Generate | `false` (Off) | Mipmaps are for 3D distance rendering, unnecessary for 2D pixel art |
| Repeat | `Disabled` | Unless you specifically need tiling textures |

> **Note on existing assets:** Changing import defaults only affects **newly imported** files. To update existing files, select them in the FileSystem dock, change settings in the Import tab, and click "Reimport."

#### Per-File Import Settings

1. Select the file in the FileSystem dock.
2. Go to the **Import** tab (next to Scene tab, top-left area).
3. Adjust settings.
4. Click **"Reimport"**.

**Tip:** You can select multiple files and reimport them all at once with the same settings.

### 2.6 Collision Layer Naming

**Path:** Project > Project Settings > Layer Names > 2D Physics

Godot 4 supports up to 32 collision layers for 2D physics. By default, they are numbered 1–32 with no names. **Always name your layers** — it makes the Inspector much easier to use.

#### How to Name Layers

1. Open **Project > Project Settings**.
2. In the left panel, navigate to **Layer Names > 2D Physics**.
3. Enter a name for each layer you plan to use.

#### Understanding Layers vs. Masks

- **Layer** = "I exist on this layer" (what the object IS)
- **Mask** = "I can detect objects on this layer" (what the object SEES)

Example: A Player on Layer 2 (Player) with Mask on Layer 1 (World) means: "I am a Player, and I collide with the World."

#### Recommended Universal Layer Assignments

| Layer # | Name | Description |
|---------|------|-------------|
| 1 | World | Static geometry: walls, floors, obstacles, tilemap collision |
| 2 | Player | The player character |
| 3 | Enemies | Enemy characters |
| 4 | PlayerHurtbox | Area where player can be hit |
| 5 | EnemyHurtbox | Area where enemies can be hit |
| 6 | PlayerHitbox | Player's attack area |
| 7 | EnemyHitbox | Enemy attack area |
| 8 | Collectibles | Coins, hearts, items, pickups |
| 9 | Interactables | NPCs, signs, chests, doors |
| 10 | Projectiles | Bullets, arrows, magic |
| 11 | Triggers | Area triggers for events, zone transitions |

> **Best practice:** Leave gaps between layer groups so you can insert new layers later without renumbering. Start with what you need and add more as the game grows.

> **Performance note:** Only enable layers in a node's Mask that it actually needs to detect. More mask layers = more physics checks.

### 2.7 Autoloads (Singletons)

**Path:** Project > Project Settings > Autoload (tab at top)

Autoloads are scripts or scenes that are loaded automatically when the game starts and persist across scene changes. They act as global singletons.

#### How to Add an Autoload

1. Open **Project > Project Settings**.
2. Click the **Autoload** tab.
3. In the **Path** field, browse to your script or scene file.
4. In the **Node Name** field, enter the name (e.g., `GameManager`). This becomes the global access name.
5. Ensure **Enable** is checked.
6. Click **Add**.

#### Accessing Autoloads from Code

```gdscript
# Access by name directly (Godot adds them to the scene tree root)
GameManager.score += 100
AudioManager.play_sfx("coin")
Events.player_died.emit()
```

#### Recommended Autoloads for Game Templates

| Autoload | Script Name | Purpose |
|----------|-------------|---------|
| **GameManager** | `game_manager.gd` | Game state, score, level management, pause |
| **AudioManager** | `audio_manager.gd` | Music and SFX playback, volume control, crossfading |
| **Events** | `events.gd` | Global signal bus for decoupled communication |
| **SaveManager** | `save_manager.gd` | Save/load game data |
| **SceneManager** | `scene_manager.gd` | Scene transitions with fade effects |

> **Best practice:** Use autoloads sparingly. Only make something an autoload if it truly needs to persist across scenes and be globally accessible. For game-specific logic, prefer regular nodes in the scene tree.

> **Signal bus pattern:** Instead of connecting signals between distant nodes, use a global `Events` autoload with custom signals. Any node can emit or connect to these signals without direct references.

```gdscript
# events.gd (Autoload)
extends Node

signal player_died
signal coin_collected(value: int)
signal level_completed
signal dialog_started(dialog_id: String)
```

### 2.8 Version Control (Git)

#### If You Selected "Git" During Project Creation

Godot creates a basic `.gitignore`. You should verify and extend it:

```gitignore
# Godot 4+ .gitignore

# Godot-specific ignores
.godot/

# Exported builds
export/
exports/
build/

# OS-specific
.DS_Store
Thumbs.db

# IDE
.vscode/
*.code-workspace
```

#### Recommended `.gitattributes`

```gitattributes
# Normalize line endings
* text=auto

# Godot files
*.gd text eol=lf
*.tscn text eol=lf
*.tres text eol=lf
*.godot text eol=lf
*.cfg text eol=lf
*.import text eol=lf

# Binary assets (use Git LFS if available)
*.png binary
*.jpg binary
*.jpeg binary
*.wav binary
*.ogg binary
*.mp3 binary
*.ttf binary
*.otf binary
*.glb binary
*.gltf binary
```

#### Files to Track vs. Exclude

| Track (commit) | Exclude (.gitignore) |
|-----------------|---------------------|
| `project.godot` | `.godot/` (entire folder) |
| `*.gd` (scripts) | `*.import` files (generated, but some teams track these) |
| `*.tscn` (scenes) | `export_presets.cfg` (may contain paths) |
| `*.tres` (resources) | |
| `*.png`, `*.wav` (assets) | |
| `export_presets.cfg` (optional) | |

> **Note on `.import` files:** These are auto-generated by Godot when importing assets. Some teams exclude them (Godot regenerates them), others track them to avoid reimport delays on clone. Either approach works.

#### Git Integration in Godot Editor

Godot has a built-in Version Control panel: **Project > Version Control > Set Up Version Control**. However, most developers use external Git tools (command line, VS Code, GitHub Desktop) rather than Godot's built-in integration, as it is limited.

---

## 3. Genre-Specific Setup

### 3.1 Top-Down RPG (Zelda-like)

#### Viewport & Display

| Setting | Recommended Value | Reasoning |
|---------|-------------------|-----------|
| Viewport Width | `320` or `640` | Shows enough of the map for exploration. 320 = more retro, 640 = more visible area. |
| Viewport Height | `180` or `360` | 16:9 aspect ratio |
| Stretch Mode | `viewport` | True pixel-perfect rendering for authentic retro RPG feel |
| Scale Mode | `integer` | Clean pixel scaling |
| Window Override | `1280×720` or `1920×1080` | Testing window |

#### Input Map

**Path:** Project > Project Settings > Input Map

| Action Name | Keyboard Keys | Gamepad | Description |
|-------------|---------------|---------|-------------|
| `move_up` | W, Up Arrow | Left Stick Up, D-Pad Up | Movement |
| `move_down` | S, Down Arrow | Left Stick Down, D-Pad Down | Movement |
| `move_left` | A, Left Arrow | Left Stick Left, D-Pad Left | Movement |
| `move_right` | D, Right Arrow | Left Stick Right, D-Pad Right | Movement |
| `attack` | J, Z, Space | A / Cross (×) | Sword/weapon attack |
| `interact` | K, X, Enter | B / Circle (○) | Talk to NPCs, open chests, read signs |
| `inventory` | I, Tab | Y / Triangle (△) | Open inventory/menu |
| `pause` | Escape, P | Start | Pause menu |
| `secondary` | L, C | X / Square (□) | Secondary item/ability |

> **Best practice:** Always map both WASD and Arrow Keys to movement actions. This costs nothing and supports both preferences. Add gamepad inputs too — Godot handles mixed input seamlessly.

> **Implementation tip:** Use `Input.get_vector("move_left", "move_right", "move_up", "move_down")` for 8-directional movement. It auto-normalizes the vector, preventing faster diagonal movement.

#### Collision Layers

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

#### Physics Settings

| Setting | Path | Value |
|---------|------|-------|
| Default Gravity | Physics > 2D > Default Gravity | `0` (no gravity in top-down view) |
| Physics FPS | Physics > Common > Physics Ticks Per Second | `60` (default, fine for most RPGs) |

> **Important:** For top-down games, set gravity to 0. The default gravity (980) is for side-view games. Top-down RPGs simulate movement on a flat plane.

#### Camera Setup

- Use **Camera2D** attached to (or following) the Player node.
- Set `Position Smoothing` > `Enabled` = `true` for smooth camera follow.
- Set `Position Smoothing` > `Speed` = `5.0` – `8.0` (adjust to taste).
- Set `Drag` margins if you want Zelda-style room-snapping (camera only moves when player crosses a threshold).
- Keep `Zoom` at `Vector2(1, 1)` — integer zoom only.

#### Recommended Autoloads

| Autoload | Purpose |
|----------|---------|
| GameManager | Current dungeon, player stats, quest flags |
| DialogManager | Dialog boxes, NPC conversations |
| Events | Global signal bus |
| AudioManager | Overworld music, dungeon music, SFX |
| SaveManager | Save slots, player progress |

#### Folder Structure

```
res://
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
├── scenes/
│   ├── characters/
│   │   ├── player.tscn
│   │   └── enemies/
│   ├── world/
│   │   ├── overworld.tscn
│   │   └── dungeons/
│   ├── ui/
│   │   ├── hud.tscn
│   │   ├── dialog_box.tscn
│   │   ├── inventory.tscn
│   │   └── pause_menu.tscn
│   └── objects/
│       ├── chest.tscn
│       ├── door.tscn
│       └── sign.tscn
├── scripts/
│   ├── autoload/
│   │   ├── game_manager.gd
│   │   ├── events.gd
│   │   └── audio_manager.gd
│   ├── characters/
│   ├── objects/
│   └── ui/
└── resources/
    ├── themes/
    └── data/
```

---

### 3.2 Platformer

#### Viewport & Display

| Setting | Recommended Value | Reasoning |
|---------|-------------------|-----------|
| Viewport Width | `640` or `426` | Wider viewport for side-scrolling. 640 shows more level. |
| Viewport Height | `360` or `240` | 16:9 aspect ratio |
| Stretch Mode | `viewport` | Authentic pixel-perfect platformer look |
| Scale Mode | `integer` | Clean pixel scaling |
| Window Override | `1280×720` or `1920×1080` | Testing window |

> **Note:** Some platformers use slightly wider viewports (e.g., 480×270) to give the player more horizontal visibility for jumps.

#### Input Map

| Action Name | Keyboard Keys | Gamepad | Description |
|-------------|---------------|---------|-------------|
| `move_left` | A, Left Arrow | Left Stick Left, D-Pad Left | Horizontal movement |
| `move_right` | D, Right Arrow | Left Stick Right, D-Pad Right | Horizontal movement |
| `jump` | Space, W, Up Arrow | A / Cross (×) | Jump (hold for variable height) |
| `attack` | J, Z | X / Square (□) | Melee attack |
| `dash` | Shift, K | B / Circle (○) | Dash/dodge |
| `pause` | Escape, P | Start | Pause menu |
| `interact` | E, X, Enter | Y / Triangle (△) | Interact with objects |

> **Note:** No `move_up` / `move_down` unless you have ladders or climbing mechanics. Adding them later is easy.

> **Variable jump height:** Check `Input.is_action_just_released("jump")` and reduce upward velocity to allow short hops vs. full jumps.

#### Collision Layers

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

#### Physics Settings

| Setting | Path | Value | Notes |
|---------|------|-------|-------|
| Default Gravity | Physics > 2D > Default Gravity | `980` (default) or custom | 980 is Earth-like. Adjust for game feel. |
| Physics FPS | Physics > Common > Physics Ticks Per Second | `60` | Standard for platformers |

**Gravity tuning guide:**

| Gravity Value | Feel | Example Games |
|---------------|------|---------------|
| 600–800 | Floaty, moon-like | Celeste-style (with fast fall) |
| 980 (default) | Earth-like, balanced | General purpose |
| 1500–2500 | Heavy, snappy | Fast-paced action platformers |
| 3000–4000 | Very heavy, arcade | Used with large sprites and high jump velocity |

> **Important:** Gravity, jump speed, and sprite size are all related. A 16px character at 640×360 needs different values than a 64px character. Start with defaults and tune iteratively.

**Typical movement values (for a ~32px character at 640×360 viewport):**

```gdscript
@export var speed: float = 300.0       # Horizontal movement speed
@export var jump_velocity: float = -500.0  # Jump force (negative = up)
@export var gravity: float = 980.0     # Gravity (or use ProjectSettings)

# Advanced:
@export var acceleration: float = 0.25  # How quickly to reach max speed
@export var friction: float = 0.1       # How quickly to stop
@export var coyote_time: float = 0.1    # Seconds of grace after leaving edge
@export var jump_buffer: float = 0.1    # Seconds of jump input buffering
```

#### Camera Setup

- **Camera2D** following the Player.
- `Position Smoothing` enabled, Speed = `5.0` – `10.0`.
- Set **Limit** properties to constrain camera to level bounds.
- Consider `Drag` horizontal margins so camera leads slightly ahead of movement direction.
- For parallax backgrounds: use **ParallaxBackground** + **ParallaxLayer** nodes. Set `Motion > Scale` to values < 1.0 (e.g., `0.5` for half-speed scrolling).

#### Recommended Autoloads

| Autoload | Purpose |
|----------|---------|
| GameManager | Lives, score, current level, checkpoints |
| Events | Global signal bus |
| AudioManager | Music and SFX |
| SceneManager | Level transitions with fade effects |

---

### 3.3 Tower Defense

#### Viewport & Display

| Setting | Recommended Value | Reasoning |
|---------|-------------------|-----------|
| Viewport Width | `640` | Needs to show the full map or large portion of it |
| Viewport Height | `360` | 16:9 aspect ratio |
| Stretch Mode | `canvas_items` | **Preferred over viewport** — tower defense has lots of UI (menus, tower info panels, resource counters). `canvas_items` renders UI text at full resolution for readability. |
| Stretch Aspect | `expand` | Allows flexible window sizing without black bars. UI anchors handle layout. |
| Scale Mode | `fractional` | Integer scaling is less important here since `canvas_items` mode handles scaling differently. |
| Window Override | `1280×720` | Testing window |

> **Why `canvas_items` for tower defense:** This genre is UI-heavy. Players constantly read tower stats, wave info, resource counts. `canvas_items` mode keeps text crisp while sprites remain pixel-perfect. `viewport` mode would make small UI text pixelated and hard to read.

#### Input Map

| Action Name | Keyboard Keys | Gamepad | Description |
|-------------|---------------|---------|-------------|
| `select` | Left Mouse Button | A / Cross (×) | Select tile / place tower |
| `cancel` | Right Mouse Button, Escape | B / Circle (○) | Cancel placement / deselect |
| `pause` | P, Space | Start | Pause game |
| `speed_up` | F, Tab | Right Bumper | Fast-forward waves |
| `speed_normal` | G | Left Bumper | Return to normal speed |
| `tower_1` | 1 | D-Pad Up | Quick-select tower type 1 |
| `tower_2` | 2 | D-Pad Right | Quick-select tower type 2 |
| `tower_3` | 3 | D-Pad Down | Quick-select tower type 3 |
| `tower_4` | 4 | D-Pad Left | Quick-select tower type 4 |
| `upgrade` | U, E | Y / Triangle (△) | Upgrade selected tower |
| `sell` | S, Delete | X / Square (□) | Sell selected tower |

> **Note:** Tower defense is primarily mouse-driven on desktop. Keyboard shortcuts are for power users. Gamepad support is optional but adds console compatibility.

#### Collision Layers

| Layer # | Name | Used By |
|---------|------|---------|
| 1 | World | Map boundaries, non-placeable areas |
| 2 | Path | Enemy walk path (for pathfinding) |
| 3 | Enemies | Enemy bodies |
| 4 | Towers | Placed tower collision (to prevent overlapping) |
| 5 | TowerRange | Tower detection radius (Area2D) |
| 6 | Projectiles | Tower projectiles |
| 7 | PlacementGrid | Valid placement zones |

#### Physics Settings

| Setting | Path | Value |
|---------|------|-------|
| Default Gravity | Physics > 2D > Default Gravity | `0` (no gravity — top-down or isometric view) |
| Physics FPS | Physics > Common > Physics Ticks Per Second | `60` |

#### Camera Setup

- **Camera2D** at fixed position (no player to follow).
- May allow zoom in/out: `Zoom` between `Vector2(0.5, 0.5)` and `Vector2(2, 2)`.
- May allow panning with middle mouse button or WASD.
- Set **Limit** properties to map boundaries.

#### UI Considerations

- Use **CanvasLayer** for UI elements (HUD, tower selection panel, wave info).
- Design UI with **Anchors** and **Containers** for responsive layout.
- Tower info panel: use **PanelContainer** with **VBoxContainer** children.
- Resource display: anchored to top of screen.
- Tower selection: anchored to bottom or side panel.

#### Recommended Autoloads

| Autoload | Purpose |
|----------|---------|
| GameManager | Wave state, resources (gold), game speed, tower inventory |
| Events | Global signal bus (tower_placed, enemy_died, wave_started) |
| AudioManager | Music and SFX |
| TowerDatabase | Tower stats, costs, upgrade paths (could be a Resource instead) |

---

### 3.4 Puzzle

#### Viewport & Display

| Setting | Recommended Value | Reasoning |
|---------|-------------------|-----------|
| Viewport Width | `640` | Good balance for grid-based puzzles |
| Viewport Height | `360` | 16:9 aspect ratio |
| Stretch Mode | `canvas_items` | **Preferred** — puzzle games are UI-heavy. Need crisp text for instructions, scores, move counters. |
| Stretch Aspect | `keep` or `expand` | `keep` for fixed-layout puzzles, `expand` for responsive |
| Scale Mode | `integer` or `fractional` | `integer` if pure pixel art, `fractional` if UI clarity matters more |
| Window Override | `1280×720` | Testing window |

> **Alternative:** For puzzles that are purely UI-based (no pixel art sprites), consider using a higher base resolution like `1280×720` with `canvas_items` mode and skip pixel-art-specific settings entirely.

#### Input Map

| Action Name | Keyboard Keys | Gamepad | Description |
|-------------|---------------|---------|-------------|
| `select` | Left Mouse Button | A / Cross (×) | Select / place piece |
| `cancel` | Right Mouse Button, Escape | B / Circle (○) | Cancel / deselect |
| `undo` | Ctrl+Z, Z | X / Square (□) | Undo last move |
| `redo` | Ctrl+Y, Shift+Z | Y / Triangle (△) | Redo last undo |
| `rotate_cw` | R, E | Right Bumper | Rotate piece clockwise |
| `rotate_ccw` | Shift+R, Q | Left Bumper | Rotate piece counter-clockwise |
| `pause` | Escape, P | Start | Pause menu |
| `hint` | H | Right Stick Click | Show hint |
| `restart` | Ctrl+R | Select/Back | Restart current puzzle |
| `move_up` | W, Up Arrow | Left Stick Up, D-Pad Up | Grid navigation (if no mouse) |
| `move_down` | S, Down Arrow | Left Stick Down, D-Pad Down | Grid navigation |
| `move_left` | A, Left Arrow | Left Stick Left, D-Pad Left | Grid navigation |
| `move_right` | D, Right Arrow | Left Stick Right, D-Pad Right | Grid navigation |

> **Note:** Puzzle games vary wildly in input needs. A Tetris clone needs rotate + move. A point-and-click puzzle only needs mouse. Customize to your specific puzzle type.

#### Collision Layers

Puzzle games often need fewer collision layers (or none at all if purely UI-based):

| Layer # | Name | Used By |
|---------|------|---------|
| 1 | World | Grid boundaries |
| 2 | Pieces | Puzzle pieces / blocks |
| 3 | Targets | Goal positions / slots |
| 4 | Clickable | Clickable areas (Area2D for mouse detection) |

> **Note:** Many puzzle games use raycasting or `_input_event` on Area2D nodes rather than physics collision. Collision layers may not be needed at all.

#### Physics Settings

| Setting | Path | Value |
|---------|------|-------|
| Default Gravity | Physics > 2D > Default Gravity | `0` (unless physics-based puzzle like Angry Birds) |
| Physics FPS | Physics > Common > Physics Ticks Per Second | `60` |

#### Animation Settings

Puzzle games rely heavily on animations for feedback:

- Use **Tween** nodes (or `create_tween()`) for piece movement, UI transitions, score popups.
- Use **AnimationPlayer** for more complex sequences (level complete celebrations).
- Consider **Timer** nodes for move countdowns or timed puzzles.
- For grid-based movement, tween pieces between grid positions:

```gdscript
func move_piece(piece: Node2D, target_grid_pos: Vector2i) -> void:
    var target_world_pos = grid_to_world(target_grid_pos)
    var tween = create_tween()
    tween.tween_property(piece, "position", target_world_pos, 0.2) \
         .set_trans(Tween.TRANS_QUAD) \
         .set_ease(Tween.EASE_OUT)
```

#### UI Considerations

- **Level select screen:** Grid of buttons, use **GridContainer**.
- **Move counter / score:** Anchored to top, use **Label** or **RichTextLabel**.
- **Undo/redo buttons:** Anchored to bottom or side panel.
- **Level complete popup:** **CenterContainer** with **PanelContainer**.
- Use **Theme** resources for consistent styling across all UI.

#### Recommended Autoloads

| Autoload | Purpose |
|----------|---------|
| GameManager | Current level, move count, stars/score, unlock state |
| Events | Global signal bus (puzzle_solved, move_made, undo_triggered) |
| AudioManager | Music and SFX |
| SaveManager | Level progress, best scores, settings |
| LevelDatabase | Level definitions, difficulty data (could be Resource files instead) |

---

## 4. Common Mistakes to Avoid

### Setup Mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| Forgetting to set Default Texture Filter to Nearest | All pixel art looks blurry and smeared | Project Settings > Rendering > Textures > Canvas Textures > Default Texture Filter = `Nearest` |
| Using Lossy compression for pixel art textures | Artifacts, color bleeding, ruined sprites | Set import Compress > Mode to `Lossless` |
| Setting non-integer Window Override size | Uneven pixels, some pixels larger than others | Window Override must be an exact integer multiple of Viewport size (e.g., 320×180 → 1280×720 = 4×) |
| Not naming collision layers | Inspector shows numbers only, impossible to manage in complex projects | Name all layers in Project Settings > Layer Names > 2D Physics |
| Using Forward+ renderer for 2D pixel art | Higher GPU requirements, no web export, no benefit for 2D | Use Compatibility renderer |
| Keeping default gravity (980) in top-down games | Objects fall "downward" in what should be a flat-plane game | Set Physics > 2D > Default Gravity = `0` for top-down games |

### Pixel Art Mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| Camera zoom at non-integer values (e.g., 1.5×) | Some pixels rendered larger than others, inconsistent look | Only use integer zoom: 1×, 2×, 3×, etc. |
| Using Camera2D smoothing without pixel snap | Sprites shimmer and jitter as camera moves between pixels | Enable Snap 2D Transforms to Pixel, or disable smoothing |
| Mixing pixel art resolutions (16px chars with 32px tiles) | Inconsistent pixel density breaks the retro aesthetic | Keep all art at the same pixel density |
| Using particle effects in viewport stretch mode | Particles look jagged and low-res | Either accept the retro look, switch to canvas_items, or render particles on a separate higher-res viewport |
| Scaling sprites in the editor (setting Scale to 2, 2) | Breaks pixel alignment, makes collision sizing confusing | Keep Scale at (1, 1). Use viewport scaling to make everything bigger. |

### Project Structure Mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| Not setting up .gitignore before first commit | `.godot/` folder (hundreds of MB) committed to repo | Create .gitignore with `.godot/` before `git add` |
| Putting all scripts in root folder | Unmanageable as project grows | Use organized folder structure from the start |
| Creating too many autoloads | Tight coupling, hard to test, "god object" pattern | Only autoload truly global systems (3–5 max) |
| Hand-editing project.godot instead of using the editor | Syntax errors, missing defaults, hard to debug | Always use the Project Settings window |
| Not setting up Input Map early | Hardcoded key checks scattered throughout code | Define all input actions before writing gameplay code |

---

## 5. Sources

### Official Documentation
- [Multiple Resolutions — Godot Engine Documentation](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
- [Renderers — Godot Engine Documentation](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- [Singletons (Autoload) — Godot Engine Documentation](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)
- [Version Control Systems — Godot Engine Documentation](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html)
- [Collision Shapes (2D) — Godot Engine Documentation](https://docs.godotengine.org/en/stable/tutorials/physics/collision_shapes_2d.html)
- [Kinematic Character (2D) — Godot Engine Documentation](https://docs.godotengine.org/en/stable/tutorials/physics/kinematic_character_2d.html)
- [Controllers, Gamepads, and Joysticks — Godot Engine Documentation](https://docs.godotengine.org/en/stable/tutorials/inputs/controllers_gamepads_joysticks.html)

### Community Tutorials & Guides
- [Setting Up Pixel Art Graphics in Godot 4 — GDQuest](https://www.gdquest.com/library/pixel_art_setup_godot4/)
- [Project Setup — Godot 4 Recipes (KidsCanCode)](https://kidscancode.org/godot_recipes/4.x/games/first_2d/first_2d_01/index.html)
- [Platform Character — Godot 4 Recipes (KidsCanCode)](https://kidscancode.org/godot_recipes/4.x/2d/platform_character/)
- [Godot 4 Pixel Art Settings — ZodmanPerth (GitHub Gist)](https://gist.github.com/ZodmanPerth/52ebc7622c6d66e4b11e1662a3e3ed66)
- [Godot 4 Sprites: Pixel-Perfect 2D Setup Guide — Sprite-AI](https://www.sprite-ai.art/guides/godot-sprites)
- [Godot 4.4 Settings for Pixel Art — itch.io Blog](https://itch.io/blog/806788/godot-44-settings-for-pixel-art)
- [Project Settings for a Pixel Art Game on Godot — Witch Cabin Games](https://witchcabingames.itch.io/truthbane/devlog/1006819/project-settings-for-a-pixelart-game-on-godot)
- [Display Scaling in Godot 4 — Chickensoft](https://chickensoft.games/blog/display-scaling)
- [Collision Layers and Masks in Godot 4 — GoTut](https://www.gotut.net/collision-layers-and-masks-in-godot-4/)
- [Collision Layer Best Practices — Godot Forum](https://forum.godotengine.org/t/whats-the-best-practice-for-setting-up-collision-layers-masks/121503)
- [Input Actions — Godot 4 Recipes (KidsCanCode)](https://kidscancode.org/godot_recipes/4.x/input/input_actions/)
- [Difference Between Forward+ and Compatibility Renderer for 2D — Godot Forum](https://forum.godotengine.org/t/difference-between-forward-and-compability-renderer-for-2d-games/52280)
- [Zelda-like Tutorial for Godot 4 — fornclake](https://fornclake.dev/posts/player-movement-animation/)
- [Doing Pixel-Perfect in Godot the Right Way — Medium](https://medium.com/codex/doing-pixel-perfect-in-godot-the-right-way-77cd39f8f23d)
