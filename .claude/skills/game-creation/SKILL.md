---
name: game-creation
description: >-
  Workflow orchestration skill for building game prototypes with Claude Code + Godot MCP.
  Activate this skill whenever starting a new game project, resuming game development work,
  planning game mechanics or features, or the user says anything like "build a game",
  "create a game", "make a platformer", "make an RPG", "let's build a shooter", "start a
  new Godot project". Also activate when discussing game architecture, scoping a prototype,
  or choosing between game genres. This is the top-level conductor — it coordinates the
  entire process from concept to playable prototype. Even if you know how to build games,
  use this skill: it codifies lessons from real sessions that prevent hours wasted on silent
  MCP failures, wrong sprite layouts, and missing collision shapes.
---

# Game Creation Workflow

Build game prototypes from concept to playable in one session. This skill orchestrates the process — what to do, in what order, and which other skills handle the details.

## Skill Ecosystem

You are the orchestrator. These specialized skills handle implementation:

| Skill | Handles | Activate When |
|-------|---------|---------------|
| `gdscript` | GDScript syntax, patterns, type safety | Writing or editing any .gd file |
| `godot-mcp` | MCP tool params, workflow sequence, known bugs | Any MCP tool call (create_scene, run_project, etc.) |
| `tscn-editor` | .tscn/.tres format, safe editing, property syntax | Any manual edit to scene/resource files |
| `godot` | Engine architecture, node types, CLI, validation | Scene structure decisions, debugging Godot errors |

## Orchestrator Model

The main agent plans, reviews, and talks to the user. Heavy work goes to subagents to preserve context:

| Subagent | Role | When to Delegate |
|----------|------|------------------|
| **godot-builder** | MCP operations + debug loop | Scene creation, running/testing the game |
| **gdscript-writer** | GDScript with Context7 grounding | Writing .gd files, fixing code bugs |
| **asset-pipeline** | Sprite analysis, asset import | Before writing animation code |

MCP operations consume thousands of tokens in tool call overhead. Writing scripts requires Context7 lookups. Keeping these in subagents preserves main context for planning and user interaction.

When delegating, tell the subagent:
- Which skills to activate (e.g., "use the godot-mcp and tscn-editor skills")
- The project path and relevant file paths
- What to build and what conventions to follow (point to CLAUDE.md)
- Where to save output files

## The Game Creation Flow

### Phase 1: Discovery & Design

This phase follows a structured interview process. DO NOT skip it. DO NOT proceed to Phase 2 without completing the quality gate. A well-defined game concept prevents hours of rework later.

Read `references/discovery-interview.md` for the full interview script and quality gate checklist.

**Step 1: Discovery Interview**

Run the 20-question interview from `references/discovery-interview.md`. The questions cover five rounds: Vision, Mechanics, Content, Scope, and Feel. Ask conversationally — group related questions, skip what the user already answered, push for concrete numbers instead of vague descriptions. If the user says "you decide," offer 2-3 options with tradeoffs and let them choose.

If the user is new to game dev, read `references/gamedev-for-engineers.md` first — it explains game loops, state machines, collision layers, and "juice" in terms a software engineer already understands.

**Step 2: Draft the GDD**

Using the interview answers, write a `GDD.md` following the templates in `references/gdd-guide.md`. Start with the one-pager. Expand to the prototype GDD template if the concept warrants it. Every mechanic must have concrete numbers — "speed: 150px/s", "HP: 6", "detection range: 128px" — not adjectives.

**Step 3: User Review**

Present the GDD to the user. Summarize the key decisions. Ask: "Does this capture what you want? Should I change anything?" Iterate until the user explicitly approves.

**Step 4: Quality Gate**

Run the three-gate checklist from `references/discovery-interview.md`:
- **Gate 1: GDD Completeness** — elevator pitch, design pillars, core loop, player stats, enemy stats, win/lose conditions, scope tiers
- **Gate 2: Implementation Readiness** — all values are numbers, collision layers assigned, no contradictions, CLAUDE.md drafted
- **Gate 3: Asset Readiness** — asset requirements listed, sources identified, art style consistent

**If any gate fails, go back and fill the gap with the user.** Do not proceed.

**Step 5: Generate CLAUDE.md**

Create the project's `CLAUDE.md` from the GDD: file structure, collision layer table with bitmask values, coding conventions, input map, anti-patterns. This is the implementation source of truth for all subagents.

If a `templates/{genre}/` starter kit exists, use it as a starting point — it includes a pre-configured CLAUDE.md, asset source lists, and setup instructions.

**Outputs (both required before proceeding):**
1. `GDD.md` — The design source of truth (what game we're making and why)
2. `CLAUDE.md` — The implementation source of truth (how we build it)

### Phase 2: Asset Pipeline

Assets before code. You cannot write animation code without knowing sprite sheet layouts. The GDD's art direction and entity list drive the asset search.

1. **Extract asset requirements from GDD** — List every entity that needs sprites (player, each enemy type, NPCs, items), every environment element (tilesets, backgrounds), every UI element (hearts, bars, buttons), and every audio need (music tracks, SFX per action). The GDD section 8 (Audio) and section 9 (Art) define the requirements.
2. **Search for free assets matching requirements** — Check ASSET-SOURCES.md if available for the genre. Search itch.io, Kenney, OpenGameArt, CraftPix. Present 2-3 options per category to the user with links and style previews. For simple UI elements (hearts, icons), generate them with Python/Pillow instead of hunting for packs. Ensure all assets match the GDD's art style (same pixel size, compatible palette).
3. **Organize into project folders:**
   ```
   assets/sprites/player/    assets/audio/music/
   assets/sprites/enemies/   assets/audio/sfx/
   assets/sprites/ui/        assets/fonts/
   assets/tilesets/
   ```
4. **Analyze every sprite sheet** — Delegate to the **asset-pipeline** subagent. Before writing ANY animation code, determine:
   - Sheet dimensions and frame size (common: 16, 32, 48, 64 pixels)
   - Columns and rows per sheet (different sheets from the same pack may have different column counts)
   - Non-empty frames per row (some rows may have fewer frames — e.g., UP idle has 4 while others have 12)
   - Direction order (CraftPix top-down convention: DOWN=0, LEFT=1, RIGHT=2, UP=3)
   **Warning:** CraftPix sprite packs don't all use the same direction order — the Player pack uses DOWN/LEFT/RIGHT/UP but the Slime pack uses DOWN/RIGHT/LEFT/UP. Always verify direction mapping visually after first import, even with sprite analyzer output.
5. **Import assets** — `godot --headless --path <project> --import` (MCP load_sprite fails without this)

**Animation approach:** Default to `AnimatedSprite2D` with `SpriteFrames` for simpler setup. Fall back to `Sprite2D` + manual `hframes/vframes` frame stepping only if you need fine-grained control or the MCP workflow requires it.

### Phase 3: Build Core

Build incrementally. Test after EACH entity, not after building everything.

**First priority: find the fun.** Build the core mechanic (movement + the ONE thing that makes the game interesting) and validate it feels good before building everything else. If the core isn't fun, more features won't fix it.

Before building, run `launch_editor` so the user can watch nodes materialize in real-time — this is the most engaging part of the MCP workflow.

```
1. Player → test movement works (is it fun to control?)
2. Enemy  → test AI behavior
3. Combat → test hitting and dying
4. World  → test boundaries and spawning (use TileMapLayer, not TileMap — deprecated since Godot 4.3)
5. HUD    → test health display updates
```

For each entity:
1. Delegate scene creation to **godot-builder** (MCP: create_scene + add_node + load_sprite)
2. Delegate script writing to **gdscript-writer** — always instruct it to use Context7 for Godot API verification
3. Review the outputs — check: collision layer/mask bitmask values, shape sizes, script attachment, `monitoring`/`monitorable` flags on Area2D nodes
4. Run the debug loop: `run_project → get_debug_output → stop_project → fix → repeat`
5. **Ask the user to playtest** — bugs like "the slime pushes me around" or "combat doesn't feel right" are only visible to a human player
6. Move to the next entity only when the current one works

### Phase 4: Polish

Polish transforms a prototype into something that feels like a game.

1. **Audio** — Background music (AudioStreamPlayer) + sound effects (AudioStreamPlayer2D). A silent game feels unfinished; one with audio feels real. Read `references/audio-patterns.md` for bus setup, node placement, and .tscn syntax.
2. **Juice** — Screen shake, damage numbers, particles, death animations, hit flash. See `references/gamedev-for-engineers.md` for what "juice" means and why it matters.
3. **Balance** — Tune speed, damage, HP, aggro range via `@export` values (no code changes needed)
4. **Bug fixes** — Use the debug loop (run → debug → stop → fix)

### Phase 5: Wrap Up

1. **Final test** — Full playthrough from start
2. **Clean up** — Remove debug prints, organize files
3. **Update CLAUDE.md** — Document what was built and any conventions discovered
4. **Commit** — Descriptive git commit message

## Key Principles

- **Find the fun first** — Build the core mechanic and validate it feels good before adding systems around it. If movement + combat isn't fun, enemies and HUD won't fix it.
- **Build incrementally** — Player first, then enemies, then combat, then world. Test after each step. In the first real session, this caught direction mapping bugs early that would have cascaded into every entity.
- **Delegate to subagents** — MCP tool calls are context-heavy (thousands of tokens each). Keep the main session lean for planning and user interaction.
- **Test early, test often** — The debug loop should run every 5-10 minutes. Fast iteration (3-second launch via MCP) is a key advantage.
- **Scope is sacred** — If it's not in the "must have" list, it doesn't get built until everything else works.
- **Smoke test first** — When using MCP in a new environment, test every tool in a throwaway project before starting the real build. This caught 5 critical issues in the first session that would have derailed the demo.
- **Audio transforms quality** — Add it in Phase 4, not "later." "Later" usually means "never."
- **Name things** — Give the hero, the world, and the enemies names. Storytelling creates engagement and makes the process enjoyable.
- **Viewport size > camera zoom** — For 64px sprites on a top-down RPG, 426x240 viewport with zoom 1x works well. 320x180 is too zoomed in. 640x360 is too distant. Character should occupy ~25-30% of screen height.

## Anti-Patterns

Mistakes from real game-building sessions that wasted significant time:

| Anti-Pattern | What Goes Wrong | Do This Instead |
|-------------|-----------------|-----------------|
| Build everything before testing | Cascading bugs, hard to isolate root cause | Test each entity in isolation |
| All MCP calls in main session | Context window fills up, lose planning ability | Delegate to subagents |
| Guess sprite sheet layouts | Wrong direction mapping, flickering animations | Analyze sheets first (dimensions, frame count per row) |
| Assume Godot API behavior | Wrong method signatures, silent runtime bugs | Use Context7 to verify before writing |
| Skip audio ("add it later") | "Later" never comes, prototype feels unfinished | Schedule it in Phase 4 |
| No scope boundaries | Feature creep, session never ends | Write explicit "OUT OF SCOPE" list in Phase 1 |
| Fixed frame delay with varying frame counts | Some directions animate 3x faster than others | Use cycle-based duration: total_time / frame_count |
| Body-to-body collision for damage | Player gets pushed around by enemies | Use Area2D hitbox/hurtbox pattern |
| `area_entered` alone for contact damage | Damage fires once then stops forever | Add periodic `get_overlapping_areas()` polling |
| Guess camera zoom level | Too close or too far, wastes iteration cycles | For 64x64 sprites on 640x360 viewport, start at 2x zoom |
| Block all input during hurt state | Player can't escape enemies, dies 100% of the time | Keep stun short (0.3s), invincibility much longer (1.0s), allow movement after stun |
| No post-respawn invincibility | Player takes damage instantly from nearby enemies on respawn | Set `damage_cooldown = 2.0` on respawn |
| UI text in world space | Blurry at low resolution, inconsistent positioning | Use CanvasLayer for all UI (HUD, dialog boxes, damage numbers) |
| No game pause during dialog | Enemies attack while player reads text | `get_tree().paused = true` + `PROCESS_MODE_ALWAYS` on dialog nodes |
| Shared keybinds for different actions | Attack fires during dialogue, interact triggers combat | Use separate input actions + a `dialog_active` flag in GameManager to route input |

## Project Structure Convention

```
project_root/
├── project.godot        # engine settings, input map, collision layers
├── CLAUDE.md            # architecture, scope, conventions (source of truth)
├── .mcp.json            # MCP server configuration
├── assets/              # sprites, audio, fonts, tilesets
├── scenes/              # .tscn files organized by entity type
│   ├── player/
│   ├── enemies/
│   ├── ui/
│   └── world/
├── scripts/             # .gd files mirroring scene structure
│   ├── player/
│   ├── enemies/
│   ├── world/
│   ├── components/      # reusable components (health, AI, etc.)
│   └── autoloads/       # singletons (GameManager, Events signal bus)
└── resources/           # .tres files (optional, for data-driven design)
```
