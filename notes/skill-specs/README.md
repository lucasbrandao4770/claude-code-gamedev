# Skill Specs — Build Order

Each prompt file is a complete, self-contained session prompt. Copy-paste the entire file as the first message in a new Claude Code session.

## Build Order (recommended)

| # | Skill | Prompt File | Dependencies | Est. Time |
|---|-------|-------------|--------------|-----------|
| 1 | `gdscript` | `PROMPT_01_GDSCRIPT_SKILL.md` | None | 30-45 min |
| 2 | `godot-mcp` | `PROMPT_02_GODOT_MCP_SKILL.md` | None | 30-45 min |
| 3 | `tscn-editor` | `PROMPT_03_TSCN_EDITOR_SKILL.md` | None (benefits from .tscn research) | 30-45 min |
| 4 | `game-creation` | `PROMPT_04_GAME_CREATION_SKILL.md` | Best after 1-3 are done (references them) | 45-60 min |

Skills 1-3 can be built in parallel (no dependencies). Skill 4 references the others by name, so ideally build it last.

## After Building

1. All skills go to `D:\Workspace\Games\claude-game-dev\.claude\skills\{skill-name}\SKILL.md`
2. Review each skill in the main planning session for integration
3. Update root CLAUDE.md with skill loading instructions
4. Test in Session 2 (same Zelda-like RPG, better tools)
