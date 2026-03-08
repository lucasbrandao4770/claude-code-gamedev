---
name: gdscript
description: GDScript 4.x language skill for writing correct, idiomatic, type-safe GDScript code in Godot Engine projects. Activate this skill whenever writing, editing, reviewing, or debugging ANY .gd file, implementing game systems in GDScript, discussing GDScript syntax or patterns, or encountering GDScript runtime errors. Even simple scripts benefit from correct style and type safety — if the task involves GDScript in any way, use this skill. Do not skip this for "quick" scripts; most GDScript bugs come from skipping conventions on "simple" code.
---

# GDScript 4.x Language Skill

## Rule #1: Ground Godot API Calls in Context7

Before writing code that calls Godot APIs, query Context7 for the current signature. Godot's API changes between versions — `yield()` became `await`, `KinematicBody2D` became `CharacterBody2D`, `Tween.new()` became `create_tween()`. Your training data may be stale. A 10-second lookup prevents 10 minutes of debugging.

## Code Style

Follow the official Godot style guide. Godot's editor, linter, and community all expect these conventions:

- **Indentation**: Tabs (Godot convention, unlike Python's spaces)
- **Naming**: `snake_case` for variables/functions, `PascalCase` for classes/nodes, `UPPER_SNAKE_CASE` for constants
- **Private members**: Underscore prefix — `_internal_state`, `_process_idle()`
- **Signals**: Past tense — `health_changed`, `enemy_died`, `item_picked_up`
- **Files**: `snake_case.gd` matching class name (`YAMLParser` -> `yaml_parser.gd`)

## Code Ordering

Godot initializes `@onready` vars after `@export` vars, and the community expects this layout. Deviating makes scripts harder to navigate:

```
@tool / @icon / @static_unload
class_name
extends
## doc comment

signals
enums
constants
static variables
@export variables
regular variables
@onready variables

_init() -> _ready() -> _process() -> _physics_process()
remaining virtual methods
public methods
private methods (underscore-prefixed)
inner classes
```

## Type Safety

Type hints catch bugs at parse time that would otherwise crash at runtime. Use them on all signatures and variable declarations:

```gdscript
func take_damage(amount: int, from_position: Vector2) -> void:
func get_nearest_enemy() -> CharacterBody2D:
func is_alive() -> bool:

var speed: float = 100.0
var current_state: State = State.IDLE
var scores: Array[int] = [10, 20, 30]
var inventory: Dictionary[String, int] = {}  # Godot 4.4+

# Typed signal params are valid syntax but serve as editor hints,
# not runtime enforcement — Godot won't error on wrong emit types.
signal health_changed(current: int, maximum: int)
```

## @export and @onready

Use `@export` with grouping annotations so values are tunable without reading code. Use `@onready` for node refs — cleaner and safer than `get_node()` in `_ready()`. Hierarchy: `@export_category` > `@export_group` > `@export_subgroup`:

```gdscript
@export_category("Character")

@export_group("Movement")
@export var speed: float = 100.0
@export var acceleration: float = 500.0

@export_group("Combat")
@export_subgroup("Offense")
@export var attack_damage: int = 1
@export_subgroup("Defense")
@export var max_hp: int = 3

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurt_box: Area2D = $HurtBox
```

## Godot 4.x — NOT 3.x

Using Godot 3 syntax causes parse errors or silent bugs. The most common traps:

| Godot 3.x (WRONG) | Godot 4.x (CORRECT) |
|---|---|
| `yield(timer, "timeout")` | `await timer.timeout` |
| `export var x` | `@export var x` |
| `onready var x` | `@onready var x` |
| `KinematicBody2D` | `CharacterBody2D` |
| `move_and_slide(vel, up)` | `velocity = vel; move_and_slide()` |
| `Tween.new()` | `create_tween()` |
| `connect("signal", obj, "method")` | `signal_name.connect(callable)` |

## Key Patterns

These come from real debugging sessions. Each addresses a mistake that actually happened:

**Movement** — physics in `_physics_process`, visuals in `_process`. Using `_process` for movement causes frame-rate-dependent speed:

```gdscript
func _physics_process(delta: float) -> void:
    var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")
    velocity = input_dir * speed
    move_and_slide()
```

**State machine** — enum + match. Don't over-engineer for prototypes:

```gdscript
enum State { IDLE, WANDER, CHASE, HURT, DEAD }
var current_state: State = State.IDLE

func _physics_process(delta: float) -> void:
    match current_state:
        State.IDLE: _process_idle(delta)
        State.CHASE: _process_chase(delta)
```

**Signal connections** — connect in `_ready()` with typed callables:

```gdscript
func _ready() -> void:
    hurt_box.area_entered.connect(_on_hurt_box_area_entered)

func _on_hurt_box_area_entered(area: Area2D) -> void:
    if area.is_in_group("enemy_hitbox"):
        take_damage(1, area.global_position)
```

**Contact damage** — `area_entered` fires only once on overlap start. For continuous contact damage (e.g., standing on lava, enemy sitting on player), also poll overlaps periodically. Note: `get_overlapping_areas()` requires `monitoring = true` on the Area2D, and returns data from the previous physics frame (one-step stale):

```gdscript
func _physics_process(delta: float) -> void:
    if damage_cooldown <= 0.0:
        _check_overlapping_damage()

func _check_overlapping_damage() -> void:
    for area in hurt_box.get_overlapping_areas():
        if area.is_in_group("enemy_hitbox"):
            take_damage(1, area.global_position)
            return
```

**Animation with varying frame counts** — use total cycle duration, not per-frame delay. If UP has 4 frames and DOWN has 12, a fixed frame delay makes UP animate 3x faster:

```gdscript
const CYCLE_DURATION: float = 1.0

func _animate(delta: float, frame_count: int) -> void:
    anim_timer += delta
    if anim_timer >= CYCLE_DURATION:
        anim_timer -= CYCLE_DURATION
    sprite.frame = int((anim_timer / CYCLE_DURATION) * frame_count) + row_offset
```

## Common Mistakes

- **`await` in `_physics_process()`**: Does NOT block — it's worse. The engine spawns a new coroutine every physics frame while previous ones are still suspended, causing coroutine stacking with duplicate side effects. Use timers or state flags instead.
- **`preload()` vs `load()`**: `preload()` loads at parse time — use it for constants with known paths: `const BulletScn = preload("res://bullet.tscn")`. It crashes if the file is missing, so use `load()` for runtime/uncertain paths. Never `preload()` into `@export` vars — the scene instantiation overwrites the default anyway.
- **Magic numbers**: `velocity = direction * 150.0` — use `@export var speed: float = 150.0` so it's tunable and self-documenting.
- **`get_node("../SomeNode")`**: Fragile path that breaks when you reparent nodes. Use signals, groups, or `@export var target: Node2D`.
- **`Input.is_action_pressed()` in `_process()`** for movement: Causes frame-rate-dependent speed. Use `_physics_process()`.
- **`create_tween()` without storing reference**: The tween is ref-counted — if nothing holds a reference, it's collected after finishing. Store it if you need to kill/chain later: `var tween: Tween = create_tween()`. Node-bound tweens are auto-killed when the node is freed. To restart: `if tween: tween.kill()` then `tween = create_tween()`.
- **Forgetting `add_to_group()` for collision detection**: If your hitbox/hurtbox uses `is_in_group("player_hitbox")` checks, the Area2D node MUST call `add_to_group("player_hitbox")` in `_ready()`. Missing group membership causes silent failures — no errors, just no damage. Always verify groups match between emitter and receiver.
- **Modifying collision shapes in signal callbacks**: Disabling/enabling `CollisionShape2D.disabled` inside `area_entered` or `body_entered` callbacks causes "Can't change state while flushing queries" errors. Always use `set_deferred("disabled", true)` instead of direct assignment.
