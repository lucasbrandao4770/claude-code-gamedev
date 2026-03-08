# Session Prompt: Build the `gdscript` Skill

> Copy-paste this entire file as the first message in a new Claude Code session.
> Working directory: `D:\Workspace\Games\claude-game-dev`

---

## Your Task

Build a Claude Code skill called `gdscript` — a **language-specific skill for GDScript 4.x** (Godot's scripting language). This skill should activate whenever Claude Code is writing, reviewing, or debugging GDScript code.

## Mandatory Reading (do this FIRST)

Before doing anything else, read these files to understand the context:

1. `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\03-mistakes-and-fixes.md` — 14 bugs from a real game dev session. Many were caused by GDScript mistakes or assumptions.
2. `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\06-skill-building-notes.md` — Extracted patterns and rules for skill creation, including GDScript patterns that worked.
3. `D:\Workspace\Claude Code\Repositorios\claude-content-creation\notes\godot skill\2026-03-08-forge-of-worlds-mcp-testing\04-what-went-well.md` — What worked well, including GDScript quality observations.
4. `D:\Workspace\Games\claude-game-dev\examples\forge-of-worlds\CLAUDE.md` — The project's CLAUDE.md which has conventions and patterns.
5. `D:\Workspace\Games\claude-game-dev\.claude\skills\godot\SKILL.md` — The existing Godot skill (engine-level). The gdscript skill complements it at the language level.

Also fetch the official GDScript style guide via Context7 or WebSearch:
- https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
- https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html

## How This Skill Fits Into the Bigger Picture

We are building a Claude Code setup for AI-assisted game development with Godot. The skill ecosystem is:

| Skill | Level | Purpose |
|-------|-------|---------|
| **gdscript** (THIS ONE) | Language | GDScript 4.x syntax, patterns, style, API grounding |
| godot (exists) | Engine | Godot file formats, scene architecture, node types |
| godot-mcp (to be built) | Tooling | MCP tool usage, limitations, workflow |
| tscn-editor (to be built) | File format | Safe .tscn editing rules |
| game-creation (to be built) | Workflow | Orchestrating the game creation process |

The gdscript skill is the **language foundation**. Every other skill produces or consumes GDScript. If the GDScript is wrong, everything breaks.

## Skill Purpose

Ensure that ALL GDScript code written by Claude Code follows:
1. The official Godot style guide (tabs, naming, ordering)
2. Type-safe patterns (type hints on all signatures)
3. Godot 4.x API correctness (NOT Godot 3.x syntax)
4. Proven game dev patterns from real sessions
5. Context7 grounding BEFORE writing any GDScript that touches Godot APIs

## Skill Triggers

The skill should activate when:
- Writing or editing any `.gd` file
- Discussing GDScript syntax or patterns
- Debugging GDScript errors
- Reviewing GDScript code quality
- Implementing any game system in GDScript

## Key Rules to Include

### MUST DO
1. **Always ground Godot API calls in Context7** before writing code. Even if you "know" the API, check it — signatures change between Godot versions. This is the #1 rule.
2. Use tabs for indentation (official Godot convention)
3. Use type hints on ALL function signatures: `func move(direction: Vector2) -> void:`
4. Use `@export` with `@export_group()` for inspector-tunable values
5. Use `@onready` for node references (not `get_node()` in `_ready()`)
6. Follow the official code ordering: signals → enums → constants → @export vars → public vars → private vars → @onready → _ready → _process → public methods → private methods
7. Use signals for decoupled communication between nodes
8. Use `snake_case` for variables/functions, `PascalCase` for classes/nodes, `UPPER_SNAKE_CASE` for constants
9. Prefix private members with underscore: `_internal_state`
10. Use `move_and_slide()` for CharacterBody2D movement (NOT `move_and_collide()` unless you need collision info)

### MUST NOT
1. Never use Godot 3.x syntax (no `yield()`, no `export`, no `onready`, no `KinematicBody2D`)
2. Never use `Input.is_action_pressed()` in `_process()` for physics movement — use `_physics_process()`
3. Never use `preload()` for resources that might not exist yet
4. Never use `await get_tree().create_timer(x).timeout` in `_physics_process()` (blocks the physics loop)
5. Never hardcode magic numbers — use constants or `@export` variables
6. Never ignore type safety — `var x = 5` should be `var x: int = 5`
7. Never use `get_node("../SomeNode")` — use signals or `@export NodePath` for cross-node references

### Patterns to Include

```gdscript
# State machine pattern (simple, for enemies)
enum State { IDLE, WANDER, CHASE, HURT, DEAD }
var current_state: State = State.IDLE

func _physics_process(delta: float) -> void:
    match current_state:
        State.IDLE: _process_idle(delta)
        State.WANDER: _process_wander(delta)
        # ...

# Signal connection pattern
func _ready() -> void:
    hurt_box.area_entered.connect(_on_hurtbox_area_entered)

# Export group pattern
@export_group("Movement")
@export var speed: float = 100.0
@export var acceleration: float = 500.0

@export_group("Combat")
@export var max_hp: int = 3
@export var attack_damage: int = 1
@export var invincibility_duration: float = 1.0

# Animation with cycle-based timing (not fixed frame delay)
var anim_timer: float = 0.0
const CYCLE_DURATION: float = 1.0  # Total loop time in seconds

func _animate(delta: float, frame_count: int) -> void:
    anim_timer += delta
    if anim_timer >= CYCLE_DURATION:
        anim_timer -= CYCLE_DURATION
    var progress: float = anim_timer / CYCLE_DURATION
    sprite.frame = int(progress * frame_count) + row_offset
```

### Common Godot 4.x API Reminders
- `Input.get_vector("left", "right", "up", "down")` returns normalized Vector2
- `CharacterBody2D.velocity` is set before calling `move_and_slide()`
- `area_entered` fires ONCE when overlap begins — use `get_overlapping_areas()` for continuous checks
- `get_tree().paused = true` pauses everything except nodes with `process_mode = PROCESS_MODE_ALWAYS`
- `Tween` is created via `create_tween()` (not `Tween.new()`)
- `Timer` nodes auto-start only if `autostart = true` in inspector

## Deliverable

Create the skill at: `D:\Workspace\Games\claude-game-dev\.claude\skills\gdscript\SKILL.md`

Follow the `/skill-creator` best practices:
- Pushy description that clearly states when to activate
- Lean content (no redundancy with the godot skill)
- Explains "why" for each rule, not just "what"
- Test it mentally: if Claude reads this skill, will it produce better GDScript?

## Quality Check

After creating the skill, verify:
1. Does it trigger on GDScript work? (check the description)
2. Does it mandate Context7 grounding? (the #1 rule)
3. Does it avoid duplicating the godot skill? (different scope)
4. Is it under 150 lines? (lean, not bloated)
5. Does it include the patterns from real session bugs? (grounded in experience)
