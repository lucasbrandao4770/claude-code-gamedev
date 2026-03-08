# Session 6 Prompt: New Game — Full GDD Pipeline

> Copy-paste this entire file as the first message in a new Claude Code session.
> Working directory: `D:\Workspace\Games\claude-game-dev`

---

## Your Mission

Build a game prototype from scratch. The user has a game idea — your job is to extract it through a structured interview, create a proper Game Design Document, find assets, and build it.

## First Steps

### 1. Read the project context
- Read `D:\Workspace\Games\claude-game-dev\CLAUDE.md` (repo overview and skill ecosystem)

### 2. The skills
The following skills are installed at `.claude/skills/` and will activate automatically:
- **game-creation** — Start here. It orchestrates the entire process.
- **gdscript** — GDScript 4.x language conventions
- **godot** — Godot engine architecture, file formats, CLI
- **godot-mcp** — MCP tool usage, workflow patterns
- **tscn-editor** — Safe .tscn/.tres editing rules

### 3. Begin

Follow the `game-creation` skill from Phase 1. It will guide you through:
1. A structured discovery interview to understand the user's game idea
2. Drafting a Game Design Document (GDD.md) with concrete values
3. A quality gate to verify everything is defined before building
4. Asset research and download
5. Building the prototype incrementally
6. Polish (audio, juice, balance)
7. Wrap up

**Do not skip the interview or quality gate.** The GDD is the foundation for everything that follows.

## Game Project Location

Create the new game at: `D:\Workspace\Games\claude-game-dev\examples\{game-name}\`
(Replace `{game-name}` with the project name chosen during the interview.)

The user will create the Godot project in the editor following the relevant template README. Claude Code takes over after that.

## Tools Available

- `tools/analyze_sprites.py` — Sprite sheet analyzer (run on downloaded assets before writing animation code)
- Godot MCP — Scene creation, running, debugging
- Templates at `templates/` — Genre-specific starter kits with CLAUDE.md, ASSET-SOURCES.md, and setup READMEs

## Metrics to Track

- Time spent in each phase (interview, asset pipeline, build, polish)
- Number of debug loop iterations
- Number of bugs and their nature
- Quality gate pass/fail on first attempt
- Which skills activated

At the end, write a session report to `notes/session6-report.md`.
