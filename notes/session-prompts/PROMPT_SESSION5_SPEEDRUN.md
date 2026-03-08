# Session 5 Prompt: Zelda-like RPG Prototype

> Copy-paste this entire file as the first message in a new Claude Code session.
> Working directory: `D:\Workspace\Games\claude-game-dev`

---

## Your Mission

Build a **2D top-down Zelda-like action RPG prototype** from scratch using Claude Code + Godot MCP.

## First Steps

### 1. Read the project context
- Read `D:\Workspace\Games\claude-game-dev\CLAUDE.md` (repo overview and skill ecosystem)
- Read `D:\Workspace\Games\claude-game-dev\templates\zelda-like-rpg\CLAUDE.md` (genre-specific conventions)
- Read `D:\Workspace\Games\claude-game-dev\templates\zelda-like-rpg\README.md` (Godot project setup reference)

### 2. The skills
The following skills are installed at `.claude/skills/` and will activate automatically:
- **gdscript** — GDScript 4.x language conventions, Context7 grounding
- **godot** — Godot engine architecture, file formats, CLI
- **godot-mcp** — MCP tool usage, workflow patterns
- **tscn-editor** — Safe .tscn/.tres editing rules
- **game-creation** — End-to-end workflow orchestration (start here)

### 3. Run the sprite analyzer on the available assets
```bash
python tools/analyze_sprites.py examples/forge-of-worlds/assets/sprites/player/ --recursive
python tools/analyze_sprites.py examples/forge-of-worlds/assets/sprites/enemies/ --recursive
```
Read the output — these frame counts and direction mappings feed directly into animation code.

## The Game Concept

**Genre:** 2D top-down action RPG (Zelda-like)
**Style:** 16-bit pixel art, nostalgic SNES/GBA feel
**Perspective:** Top-down, 4-directional movement

### Core Mechanics (MUST HAVE)
1. Player: 4-directional movement with walk/idle animations
2. Sword attack: slash in facing direction with hitbox
3. Slime enemies: wander + chase player when close + contact damage
4. Health system: player and enemies have HP
5. Damage with knockback and invincibility frames
6. Death: enemy death animation, player death → restart
7. One map: green field with boundaries
8. Camera following player
9. HUD: hearts display
10. Background music + sound effects

### SHOULD HAVE (after core works)
- Heart pickups
- NPC with dialogue box

### EXPLICITLY OUT OF SCOPE
- Inventory, equipment, drops
- Multiple maps, room transitions
- Save/load, menus
- Jump mechanic

## Assets

Pre-downloaded assets are available at `examples/forge-of-worlds/assets/`:
- `sprites/player/Swordsman_lvl1/` — CraftPix swordsman (idle, walk, attack, hurt, death, run)
- `sprites/enemies/Slime1/` — CraftPix slime (same animation types)
- `sprites/npcs/` — Pixel Crawler NPCs
- `audio/music/` — xDeviruchi 8-bit tracks (.wav)
- `audio/sfx/` — Kenney RPG sounds (.ogg)
- `fonts/PressStart2P-Regular.ttf`

Use the `With_shadow/` sprite variants. The sprite analyzer will tell you exact frame sizes, row counts, and direction layouts — **rely on its output, don't guess.**

## Game Project Location

Create the new game project at: `D:\Workspace\Games\claude-game-dev\examples\forge-of-worlds-v2\`

The user will create the Godot project in the editor first. After that, Claude Code takes over with MCP.

## Process

Follow the `game-creation` skill's Phase 1-5 flow. The skill has all the details — let it guide you.

Key points:
- Create a brief GDD and a CLAUDE.md for the new project
- Copy assets to the new project, then import them
- Build incrementally: player → test → enemy → test → combat → test → world → HUD → audio
- Delegate heavy work (MCP operations, code writing) to subagents to preserve main context

## Success Criteria

After this session, we should have:
- [ ] A playable prototype with player, enemies, combat, HUD, and audio
- [ ] Main session context kept lean (delegate to subagents)
- [ ] Code following GDScript conventions (type hints, @export groups, etc.)

## Metrics to Track

Track these during the session for the post-session report:
- Total time from start to first playable
- Number of debug loop iterations
- Number of bugs encountered and their nature
- Which skills activated and whether they helped
- Main session token usage

At the end, write a session report to `notes/session5-report.md`.
