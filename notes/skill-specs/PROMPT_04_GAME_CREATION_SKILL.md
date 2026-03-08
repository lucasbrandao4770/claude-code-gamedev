# Session Prompt: Build the `game-creation` Skill

> Copy-paste this entire file as the first message in a new Claude Code session.
> Working directory: `D:\Workspace\Games\claude-game-dev`

---

## Your Task

Build a Claude Code skill called `game-creation` — a **workflow orchestration skill for building game prototypes** with Claude Code + Godot MCP. This skill should activate when starting a new game project or resuming game development work. It codifies the proven iterative process from a real game-building session.

## Mandatory Reading (do this FIRST)

Before doing anything else, read ALL of these files — they document a complete 3-hour session where we built a 2D RPG prototype from scratch:

1. `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\01-session-summary.md` — What was built and the overall flow.
2. `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\02-mcp-tool-analysis.md` — What tools are available and their limitations.
3. `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\03-mistakes-and-fixes.md` — 14 mistakes that wasted time, with prevention strategies.
4. `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\04-what-went-well.md` — 12 things that made the session successful.
5. `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\05-improvement-suggestions.md` — Suggestions for improving the workflow.
6. `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\06-skill-building-notes.md` — Extracted rules and patterns for skill building.
7. `D:\Workspace\Games\claude-game-dev\examples\forge-of-worlds\CLAUDE.md` — The project CLAUDE.md with architecture and conventions.
8. `D:\Workspace\Games\claude-game-dev\CLAUDE.md` — The root CLAUDE.md with MCP workflow overview.

## How This Skill Fits Into the Bigger Picture

| Skill | Level | Purpose |
|-------|-------|---------|
| gdscript | Language | GDScript syntax and patterns |
| godot (exists) | Engine | Godot architecture and node types |
| godot-mcp | Tooling | MCP tool usage and workflow |
| tscn-editor | File format | Safe .tscn editing |
| **game-creation** (THIS ONE) | Workflow | **Orchestrating the entire game creation process** |

This is the **top-level orchestration skill**. It tells Claude how to run a game-building session end-to-end. It coordinates when to use the other skills, when to delegate to subagents, and how to iterate effectively.

**Critical architectural context:** The main session agent is an ORCHESTRATOR, not a worker. Heavy operations (MCP calls, code writing, asset analysis) should be delegated to specialized subagents:

| Subagent | Role | When to Invoke |
|----------|------|----------------|
| godot-builder | MCP operations (create scenes, debug loop) | Scene creation, running/testing the game |
| gdscript-writer | Code writing with Context7 grounding | Writing .gd files, fixing code bugs |
| asset-pipeline | Sprite analysis, asset import | Before writing animation code |

The main agent plans, reviews results, talks to the user, and delegates.

## Skill Purpose

Guide the game creation process from concept to playable prototype, following a proven iterative flow. The skill ensures nothing is forgotten, the right tools are used at the right time, and the process is enjoyable and educational.

## Skill Triggers

The skill should activate when:
- Starting a new game project
- Resuming game development work
- Planning game mechanics or features
- The user says "let's build a game" or "create a game"
- Discussing game architecture or scope

## The Proven Game Creation Flow

This flow was battle-tested in the "Forge of Worlds" session:

### Phase 1: Concept & Planning (interactive with user)
1. **Choose genre** — Ask the user what kind of game they want
2. **Define core mechanics** — List 5-8 must-have features, be explicit about scope
3. **Define art style** — Pixel art size, perspective (top-down, side-scroll), color palette
4. **Set explicit scope boundaries** — What is IN and what is OUT (prevents creep)
5. **Name the game** — Even a working title creates emotional investment

### Phase 2: Asset Pipeline
1. **Identify needed assets** — Characters, enemies, tilesets, UI, audio
2. **Source assets** — Search ASSET-SOURCES.md or free asset sites
3. **Download and organize** — Follow the folder structure convention
4. **Analyze sprite sheets** — Run `tools/analyze_sprites.py` if available, or manually check frame sizes and row layouts
5. **Import assets** — `godot --headless --path <project> --import`

### Phase 3: Build Core (delegate to subagents)
1. **Create project** — Either via Godot editor (recommended) or template
2. **Build player** — Movement first, then combat
3. **Test player in isolation** — Run and verify movement works
4. **Build enemies** — AI behavior, hitbox/hurtbox
5. **Build combat** — Connect hitboxes, add damage/knockback/invincibility
6. **Test combat** — Run and verify hitting/dying works
7. **Build world** — TileMap or simple background with boundaries
8. **Build HUD** — Health display, score

### Phase 4: Polish (delegate to subagents)
1. **Add audio** — Background music + sound effects
2. **Add juice** — Screen shake, damage numbers, particles, death animations
3. **Balance** — Adjust speed, damage, HP, aggro range via @export values
4. **Fix bugs** — Use the debug loop (run → debug → stop → fix)

### Phase 5: Wrap Up
1. **Final test** — Complete playthrough
2. **Clean up** — Remove debug prints, organize files
3. **Document** — Update CLAUDE.md with what was built
4. **Commit** — Git commit with descriptive message

### Key Principles
- **Build incrementally** — Player first, then enemies, then combat, then world. Test after EACH step.
- **Delegate to subagents** — Keep the main context lean. MCP operations are context-heavy.
- **Test early, test often** — The debug loop (run → debug → stop → fix) should happen every 5-10 minutes.
- **Scope is sacred** — If it's not in the "must have" list, it doesn't get built (unless everything else is done).
- **Audio transforms quality** — A silent game feels like a prototype. A game with music and SFX feels "real." Add audio early if possible.
- **Name things** — Give the hero a name, the world a name, the enemies names. Storytelling creates engagement.

### Anti-Patterns (Things That Killed Time in Session 1)
- Building everything before testing anything → test incrementally
- Doing all MCP calls in the main session → delegate to subagents
- Guessing sprite sheet layouts → analyze them first
- Assuming API behavior without checking → use Context7
- Skipping audio because "we'll add it later" → add it in Phase 4, not "later"

## Deliverable

Create the skill at: `D:\Workspace\Games\claude-game-dev\.claude\skills\game-creation\SKILL.md`

Follow `/skill-creator` best practices:
- This is a WORKFLOW skill, not a coding skill — it orchestrates, not implements
- It should reference the other skills (gdscript, godot-mcp, tscn-editor) by name
- It should mention the subagent delegation pattern
- Keep it actionable — each phase has clear steps
- The tone should be encouraging and creative (game dev is fun!)

## Quality Check

After creating:
1. Does it cover the full flow from concept to playable prototype?
2. Does it mandate incremental testing?
3. Does it reference subagent delegation?
4. Does it include the anti-patterns from real experience?
5. Does it work as a standalone guide (someone with just this skill could build a game)?
6. Is it under 200 lines? (workflow skills can be slightly longer than coding skills)
