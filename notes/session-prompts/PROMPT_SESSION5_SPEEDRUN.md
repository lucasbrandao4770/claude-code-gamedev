# Session 5 Prompt: Zelda-like RPG Speedrun

> Copy-paste this entire file as the first message in a new Claude Code session.
> Working directory: `D:\Workspace\Games\claude-game-dev`
> This session builds a new game from scratch to validate our skills and tools.

---

## Your Mission

Build a **2D top-down Zelda-like action RPG prototype** from scratch, using Claude Code + Godot MCP + the skills we've built. This is a controlled test — same concept and assets as our first prototype ("Forge of Worlds"), but with better tools and processes. The goal is to validate that our skills, sprite analyzer, and workflow patterns actually reduce time and bugs.

## Mandatory First Steps

### 1. Read the project context
- Read `D:\Workspace\Games\claude-game-dev\CLAUDE.md` (root — repo overview and skill table)
- Read `D:\Workspace\Games\claude-game-dev\templates\zelda-like-rpg\CLAUDE.md` (genre-specific conventions)
- Read `D:\Workspace\Games\claude-game-dev\templates\zelda-like-rpg\README.md` (Godot project setup steps)

### 2. Read the first session learnings
- Read `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\01-session-summary.md`
- Read `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\03-mistakes-and-fixes.md`
- Read `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\04-what-went-well.md`

### 3. Understand the available skills
The following skills are installed at `.claude/skills/` and will activate automatically:
- **gdscript** — GDScript 4.x language conventions, Context7 grounding mandate
- **godot** — Godot engine architecture, file formats, CLI
- **godot-mcp** — MCP tool usage, limitations, workflow patterns
- **tscn-editor** — Safe .tscn editing rules, validation checklist
- **game-creation** — End-to-end workflow orchestration (the main skill for this session)

### 4. Run the sprite analyzer on our assets
```bash
python tools/analyze_sprites.py examples/forge-of-worlds/assets/sprites/player/ --recursive --output notes/sprite-metadata-player.json
python tools/analyze_sprites.py examples/forge-of-worlds/assets/sprites/enemies/ --recursive --output notes/sprite-metadata-enemies.json
```
Read the output — these frame counts and direction mappings feed directly into animation code.

## The Game Concept

**Title:** Choose something fun with the user (or suggest a few options)
**Genre:** 2D top-down action RPG (Zelda-like)
**Style:** 16-bit pixel art, nostalgic SNES/GBA feel
**Perspective:** Top-down, 4/8-directional movement

### Core Mechanics (MUST HAVE)
1. Player: 4-directional movement with walk/idle animations
2. Sword attack: slash in facing direction with hitbox
3. Slime enemies: wander + chase player when close + contact damage
4. Health system: player and enemies have HP
5. Damage: flash + knockback + invincibility frames
6. Death: enemy death poof, player death → restart
7. One map: green field with boundaries
8. Camera following player
9. HUD: hearts display
10. Background music + sound effects

### SHOULD HAVE (after core works)
- Heart pickups
- NPC with dialogue box
- More enemy variety or behavior

### EXPLICITLY OUT OF SCOPE
- Inventory, equipment, drops
- Multiple maps, room transitions
- Save/load, menus
- Jump mechanic

## Assets Location

All assets are pre-downloaded at `examples/forge-of-worlds/assets/`:
- `sprites/player/Swordsman_lvl1/` — 48x48 CraftPix swordsman (idle, walk, attack, hurt, death, run, walk_attack, run_attack)
- `sprites/enemies/Slime1/` — 48x48 CraftPix slime (same animation types)
- `sprites/npcs/` — Pixel Crawler NPCs
- `audio/music/` — 10 xDeviruchi 8-bit tracks (.wav)
- `audio/sfx/` — Kenney RPG sounds (.ogg)
- `fonts/PressStart2P-Regular.ttf`

**Sprite conventions (from Session 1):**
- CraftPix direction order: DOWN=0, LEFT=1, RIGHT=2, UP=3 (row order in sprite sheets)
- Frame size: 64x64 (verified by sprite analyzer)
- Use `With_shadow/` versions for the game

## Game Project Location

Create the new game project at: `D:\Workspace\Games\claude-game-dev\examples\forge-of-worlds-v2\`

The user will create the Godot project first following the template README instructions. After that, Claude Code takes over with MCP.

## Process to Follow

Follow the `game-creation` skill's Phase 1-5 flow:

1. **Phase 1: Concept & Planning** — Quick, since the concept is already defined above. Create the CLAUDE.md and a brief GDD. Use the templates as starting points.
2. **Phase 2: Asset Pipeline** — Assets are already downloaded. Copy them to the new project folder. Run `godot --headless --import`. Run the sprite analyzer.
3. **Phase 3: Build Core** — Delegate to subagents:
   - **godot-builder subagent** for MCP operations (create scenes, add nodes, load sprites, debug loop)
   - **gdscript-writer subagent** for script writing (use Context7 for API grounding)
   - Build incrementally: player → test → enemy → test → combat → test → world → test → HUD → test
4. **Phase 4: Polish** — Add audio (BGM + SFX), balance combat, add juice (damage numbers, death anims)
5. **Phase 5: Wrap Up** — Final test, clean up, commit

## Key Differences from Session 1

| Aspect | Session 1 | This Session |
|--------|-----------|--------------|
| Skills | None | 5 skills (gdscript, godot, godot-mcp, tscn-editor, game-creation) |
| Sprite analysis | Manual trial-and-error (4 bugs) | `analyze_sprites.py` → instant metadata |
| Subagent delegation | Everything in main session | Delegate MCP + code to subagents |
| Context7 | Not used | Mandatory for every GDScript API call |
| Audio | Skipped (ran out of context) | Scheduled in Phase 4 |
| Collision pattern | Discovered body-push bug mid-session | Known from start (Area2D only) |
| Animation timing | Fixed frame delay (caused speed bugs) | Cycle-based timing from start |

## Success Criteria

After this session, we should have:
- [ ] A playable prototype with player, enemies, combat, and HUD
- [ ] Working audio (BGM + at least 3 SFX)
- [ ] Fewer debug iterations than Session 1 (target: 3-4 vs 8)
- [ ] Main session context under 100k tokens (vs 300k in Session 1)
- [ ] All code following GDScript conventions (type hints, @export groups, etc.)

## Measurement

Track these metrics during the session:
- Total time from start to first playable
- Number of debug loop iterations
- Number of bugs found
- Main session context usage (check periodically)
- Which skills activated and whether they helped

At the end of the session, write a comparison report to `notes/session5-comparison.md`.

## Important Reminders

- **Create the Godot project in the editor**, not by writing project.godot manually
- **Run `godot --headless --import` after placing assets** — this is the #1 cause of failures
- **Use Area2D for all damage**, never body-to-body collision
- **area_entered fires ONCE** — add periodic `get_overlapping_areas()` for contact damage
- **Set Vector2/Color in .tscn or _ready()**, not via MCP add_node properties
- **Separate stun duration (0.3s) from invincibility duration (1.0s)** — player needs to move during invincibility
- **Add post-respawn invincibility (2s)** — prevents instant death from nearby enemies
- **Use CanvasLayer for all UI** — HUD, dialog boxes, damage numbers
- **Pause game tree during dialog** — `get_tree().paused = true` + PROCESS_MODE_ALWAYS on dialog
