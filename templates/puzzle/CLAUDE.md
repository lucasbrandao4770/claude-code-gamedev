# Template: 2D Puzzle Game — Claude Code + Godot MCP

> **Status:** Template (not yet battle-tested). Based on patterns from the Zelda-like RPG prototype.
> Copy this folder to start a new puzzle game project.

## Project Context

A 2D puzzle game with grid-based or physics-based mechanics. Think Tetris, match-3, Sokoban, or simple physics puzzles.

## Tech Stack

- **Engine:** Godot 4.x (GDScript)
- **AI Tooling:** Claude Code + godot-mcp
- **Style:** Clean pixel art or vector, top-down or side view

## Architecture

### Core Nodes (Grid-Based)
- **Grid:** TileMap or custom Node2D with 2D array logic
- **Piece:** Sprite2D with grid position, type/color, state
- **GameBoard:** Node2D managing grid state, match detection, gravity
- **HUD:** CanvasLayer with score, moves/time, level indicator
- **Effects:** Particles for matches, clears, combos

### Core Nodes (Physics-Based)
- **Pieces:** RigidBody2D with shapes
- **Walls:** StaticBody2D boundaries
- **Goals:** Area2D target zones
- **Launcher:** Node2D with angle/force controls

### Key Mechanics (Grid)
- Grid state management: 2D array of piece types
- Match detection: horizontal/vertical/pattern scanning
- Gravity: pieces fall to fill gaps
- Input: click/drag or keyboard for piece movement
- Score system: base points + combo multipliers

### Key Mechanics (Physics)
- RigidBody2D for realistic movement
- Joint constraints for connected pieces
- Goal detection via Area2D overlap

## GDScript Conventions

- All comments in Portuguese
- snake_case for variables/functions, PascalCase for nodes/classes
- Type hints on all function signatures
- @export with @export_group() for inspector tuning

## Anti-Patterns
- DO NOT use Godot 3.x syntax
- DO NOT check matches every frame — use event-driven detection
- DO NOT animate grid pieces by moving them 1px/frame — use Tweens
- DO NOT skip `godot --headless --import` for new assets
