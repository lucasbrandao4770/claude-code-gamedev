# Technical Report: Building a 2D Top-Down Zelda-Like Action RPG in Godot 4

> **Date:** 2026-03-07
> **Engine:** Godot 4.x (GDScript)
> **Genre:** 2D Top-Down Action RPG (Zelda-like)

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Core Systems Architecture](#2-core-systems-architecture)
3. [Scene Structure](#3-scene-structure)
4. [Animation System](#4-animation-system)
5. [TileMap System](#5-tilemap-system)
6. [Common Patterns](#6-common-patterns)
7. [Minimum Viable Prototype Scope](#7-minimum-viable-prototype-scope)
8. [Sources](#sources)

---

## 1. Project Structure

### Recommended Folder Layout

```
project_root/
├── project.godot
├── assets/
│   ├── sprites/
│   │   ├── player/              # Player sprite sheets
│   │   ├── enemies/             # Enemy sprite sheets (slime.png, etc.)
│   │   ├── items/               # Pickups, hearts, keys
│   │   ├── effects/             # Attack effects, particles
│   │   └── ui/                  # HUD elements
│   ├── tilesets/
│   │   ├── overworld.png        # Tileset source image
│   │   └── dungeon.png
│   ├── audio/
│   │   ├── sfx/                 # Sound effects
│   │   └── music/               # Background music
│   └── fonts/
├── scenes/
│   ├── player/
│   │   └── player.tscn          # Player scene
│   ├── enemies/
│   │   ├── slime.tscn
│   │   └── base_enemy.tscn      # Optional: base enemy scene
│   ├── weapons/
│   │   └── sword_hitbox.tscn
│   ├── pickups/
│   │   └── heart.tscn
│   ├── ui/
│   │   ├── hud.tscn
│   │   └── pause_menu.tscn
│   ├── world/
│   │   ├── overworld.tscn       # Main world map
│   │   ├── rooms/               # Individual room scenes
│   │   │   ├── room_01.tscn
│   │   │   └── room_02.tscn
│   │   └── world.tscn           # World container/manager
│   └── components/              # Reusable scene components
│       ├── hitbox.tscn
│       ├── hurtbox.tscn
│       └── health_component.tscn
├── scripts/
│   ├── player/
│   │   ├── player.gd
│   │   └── player_states/       # State machine scripts
│   │       ├── state.gd         # Base state class
│   │       ├── idle_state.gd
│   │       ├── walk_state.gd
│   │       ├── attack_state.gd
│   │       └── hurt_state.gd
│   ├── enemies/
│   │   ├── slime.gd
│   │   └── enemy_states/
│   │       ├── patrol_state.gd
│   │       ├── chase_state.gd
│   │       └── attack_state.gd
│   ├── components/
│   │   ├── hitbox.gd
│   │   ├── hurtbox.gd
│   │   └── health_component.gd
│   └── autoloads/
│       ├── game_manager.gd      # Global game state
│       ├── events.gd            # Signal bus
│       └── audio_manager.gd     # Audio singleton
└── resources/
    ├── tilesets/
    │   ├── overworld.tres        # TileSet resources
    │   └── dungeon.tres
    └── themes/
        └── ui_theme.tres
```

### Key Organizational Principles

- **Scenes and scripts together or mirrored**: Either attach scripts directly to scenes (small projects) or mirror the folder structure between `scenes/` and `scripts/` (larger projects).
- **Components folder**: Reusable scene fragments (hitbox, hurtbox, health) live in `scenes/components/` so any entity can instance them.
- **Autoloads folder**: All singleton scripts go in `scripts/autoloads/` for easy identification.
- **Resources separate from scenes**: `.tres` files (TileSets, themes, custom Resources) live in `resources/`.

---

## 2. Core Systems Architecture

### 2.1 Player Controller (Top-Down 8-Directional Movement)

The player uses `CharacterBody2D` with `Input.get_vector()` for clean 8-directional movement. `move_and_slide()` handles delta time internally, so velocity should NOT be multiplied by delta.

```gdscript
# player.gd
extends CharacterBody2D

@export var speed: float = 120.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine = $AnimationTree["parameters/playback"]

var direction: Vector2 = Vector2.ZERO
var last_direction: Vector2 = Vector2.DOWN  # Default facing direction

func _physics_process(_delta: float) -> void:
    # Get normalized input vector (handles diagonal normalization automatically)
    direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

    if direction != Vector2.ZERO:
        last_direction = direction
        velocity = direction * speed
        update_animation("walk")
    else:
        velocity = Vector2.ZERO
        update_animation("idle")

    move_and_slide()

func update_animation(state: String) -> void:
    # Set blend position for directional animations
    animation_tree.set("parameters/idle/blend_position", last_direction)
    animation_tree.set("parameters/walk/blend_position", last_direction)
    state_machine.travel(state)
```

**Why `Input.get_vector()`?** It returns a normalized `Vector2` from four input actions, automatically handling diagonal movement so the player does not move faster diagonally (a common beginner bug).

**Input Map Setup** (Project > Project Settings > Input Map):

| Action | Default Key |
|--------|-------------|
| `move_left` | A / Left Arrow |
| `move_right` | D / Right Arrow |
| `move_up` | W / Up Arrow |
| `move_down` | S / Down Arrow |
| `attack` | Space / J |
| `interact` | E / K |

### 2.2 Combat System (Melee Sword Attack with Hitbox/Hurtbox)

The hitbox/hurtbox pattern separates "dealing damage" from "receiving damage" into two Area2D-based components with complementary collision layers.

#### Hitbox Component (Deals Damage)

```gdscript
# hitbox.gd
class_name HitBox
extends Area2D

@export var damage: int = 1
```

Scene structure for `hitbox.tscn`:
```
HitBox (Area2D)
└── CollisionShape2D  # Disabled by default
```

Inspector settings:
- `collision_layer = 2` (hitbox layer)
- `collision_mask = 0` (does not detect anything itself)
- `monitorable = true` (can be detected by hurtboxes)
- `monitoring = false` (does not detect others)
- `CollisionShape2D.disabled = true` (enabled only during attack animation)

#### Hurtbox Component (Receives Damage)

```gdscript
# hurtbox.gd
class_name HurtBox
extends Area2D

func _ready() -> void:
    area_entered.connect(_on_area_entered)

func _on_area_entered(hitbox: HitBox) -> void:
    if hitbox == null:
        return
    if owner.has_method("take_damage"):
        owner.take_damage(hitbox.damage)
```

Scene structure for `hurtbox.tscn`:
```
HurtBox (Area2D)
└── CollisionShape2D
```

Inspector settings:
- `collision_layer = 0` (no layer of its own)
- `collision_mask = 2` (detects hitbox layer)
- `monitoring = true` (actively detects)
- `monitorable = false`

#### Sword Attack Integration

The sword hitbox is a child of the player scene. Its `CollisionShape2D` is toggled by the `AnimationPlayer` during the attack animation:

```gdscript
# In player.gd — attack handling
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("attack"):
        attack()

func attack() -> void:
    state_machine.travel("attack")
    # The AnimationPlayer track enables/disables the sword collision shape

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        die()
    else:
        state_machine.travel("hurt")
```

The AnimationPlayer "attack" animation has a track that:
1. Frame 0: Enables `SwordHitBox/CollisionShape2D.disabled = false`
2. Frame N (end): Disables `SwordHitBox/CollisionShape2D.disabled = true`

This ensures the hitbox is only active during the swing frames.

### 2.3 Enemy AI (Slime: Patrol, Chase, Attack)

A simple enemy AI uses a state machine with detection via `Area2D` (detection radius) and optional `NavigationAgent2D` for pathfinding.

```gdscript
# slime.gd
extends CharacterBody2D

enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }

@export var speed: float = 40.0
@export var chase_speed: float = 60.0
@export var health: int = 3

var current_state: State = State.IDLE
var player: CharacterBody2D = null
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
var wander_timer: float = 0.0

@onready var detection_zone: Area2D = $DetectionZone
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var hurt_timer: Timer = $HurtTimer

func _ready() -> void:
    detection_zone.body_entered.connect(_on_detection_zone_body_entered)
    detection_zone.body_exited.connect(_on_detection_zone_body_exited)
    hurt_timer.timeout.connect(_on_hurt_timer_timeout)

    # Set up patrol points relative to spawn position
    var origin = global_position
    patrol_points = [
        origin + Vector2(50, 0),
        origin + Vector2(0, 50),
        origin + Vector2(-50, 0),
        origin + Vector2(0, -50),
    ]
    current_state = State.PATROL

func _physics_process(delta: float) -> void:
    match current_state:
        State.IDLE:
            _process_idle(delta)
        State.PATROL:
            _process_patrol(delta)
        State.CHASE:
            _process_chase(delta)
        State.ATTACK:
            pass  # Attack animation drives behavior
        State.HURT:
            pass  # Waiting for hurt timer
        State.DEAD:
            pass

func _process_idle(delta: float) -> void:
    velocity = Vector2.ZERO
    wander_timer -= delta
    if wander_timer <= 0:
        current_state = State.PATROL

func _process_patrol(_delta: float) -> void:
    var target = patrol_points[current_patrol_index]
    nav_agent.target_position = target

    if nav_agent.is_navigation_finished():
        current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
        current_state = State.IDLE
        wander_timer = randf_range(1.0, 3.0)
        return

    var next_pos = nav_agent.get_next_path_position()
    var dir = (next_pos - global_position).normalized()
    velocity = dir * speed
    animated_sprite.flip_h = velocity.x < 0
    move_and_slide()

func _process_chase(_delta: float) -> void:
    if player == null:
        current_state = State.PATROL
        return

    nav_agent.target_position = player.global_position

    if nav_agent.is_navigation_finished():
        return

    var next_pos = nav_agent.get_next_path_position()
    var dir = (next_pos - global_position).normalized()
    velocity = dir * chase_speed
    animated_sprite.flip_h = velocity.x < 0
    move_and_slide()

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        current_state = State.DEAD
        # Play death animation, then queue_free()
        animated_sprite.play("death")
        await animated_sprite.animation_finished
        queue_free()
    else:
        current_state = State.HURT
        animated_sprite.play("hurt")
        # Knockback
        var knockback_dir = (global_position - player.global_position).normalized()
        velocity = knockback_dir * 200.0
        move_and_slide()
        hurt_timer.start(0.5)

func _on_detection_zone_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        player = body
        current_state = State.CHASE

func _on_detection_zone_body_exited(body: Node2D) -> void:
    if body.is_in_group("player"):
        player = null
        current_state = State.PATROL

func _on_hurt_timer_timeout() -> void:
    if current_state == State.HURT:
        current_state = State.CHASE if player != null else State.PATROL
```

Slime scene tree:
```
Slime (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D           # Physics body shape
├── HurtBox (Area2D)           # Instance of hurtbox.tscn
│   └── CollisionShape2D
├── HitBox (Area2D)            # Contact damage hitbox
│   └── CollisionShape2D
├── DetectionZone (Area2D)     # Circle for detecting player
│   └── CollisionShape2D      # Large circle (e.g. 80px radius)
├── NavigationAgent2D
└── HurtTimer (Timer)
```

### 2.4 Collision Layers Setup

Godot supports up to 32 collision layers. Name them in Project Settings > General > Layer Names > 2D Physics:

| Layer # | Name | Used By |
|---------|------|---------|
| 1 | `world` | TileMap walls, static obstacles |
| 2 | `player` | Player CharacterBody2D |
| 3 | `enemies` | Enemy CharacterBody2D |
| 4 | `player_hitbox` | Player sword/weapon HitBox |
| 5 | `enemy_hitbox` | Enemy attack/contact HitBox |
| 6 | `pickups` | Hearts, keys, items |
| 7 | `interactions` | NPCs, signs, doors, chests |

**Collision matrix** (Layer = "I am", Mask = "I detect/collide with"):

| Node | Layer | Mask |
|------|-------|------|
| Player (CharacterBody2D) | 2 (player) | 1 (world), 6 (pickups), 7 (interactions) |
| Player HurtBox | — | 5 (enemy_hitbox) |
| Player Sword HitBox | 4 (player_hitbox) | — |
| Enemy (CharacterBody2D) | 3 (enemies) | 1 (world), 3 (enemies) |
| Enemy HurtBox | — | 4 (player_hitbox) |
| Enemy HitBox | 5 (enemy_hitbox) | — |
| TileMap walls | 1 (world) | — |
| Pickups (Area2D) | 6 (pickups) | 2 (player) |
| Interaction zones | 7 (interactions) | 2 (player) |

**Key rule**: HitBoxes have a layer but NO mask (they are detected, they do not detect). HurtBoxes have a mask but NO layer (they detect, they are not detected). This prevents double-firing of signals.

### 2.5 Camera System

#### Option A: Simple Follow Camera (Child of Player)

The simplest approach -- make `Camera2D` a child of the player node:

```
Player (CharacterBody2D)
├── AnimatedSprite2D
├── Camera2D             # Automatically follows parent
│   └── (configure in Inspector)
└── ...
```

Camera2D Inspector settings:
- `Position Smoothing > Enabled = true`
- `Position Smoothing > Speed = 5.0` (lower = smoother/laggier, higher = tighter)
- `Limit > Left/Top/Right/Bottom` = set to world bounds
- `Drag > Horizontal/Vertical Enabled = true` (optional dead zone)

#### Option B: Zelda-Style Room Transition Camera

For classic NES Zelda-style screen-by-screen scrolling, the camera snaps to discrete "room" positions and transitions smoothly when the player crosses a boundary.

```gdscript
# room_camera.gd
extends Camera2D

@export var transition_speed: float = 4.0

var target_position: Vector2 = Vector2.ZERO
var is_transitioning: bool = false
var viewport_size: Vector2

func _ready() -> void:
    viewport_size = get_viewport_rect().size / zoom
    target_position = global_position
    # Disable position smoothing; we handle it manually
    position_smoothing_enabled = false

func _process(delta: float) -> void:
    if is_transitioning:
        global_position = global_position.lerp(target_position, transition_speed * delta)
        if global_position.distance_to(target_position) < 1.0:
            global_position = target_position
            is_transitioning = false

func transition_to_room(room_position: Vector2) -> void:
    target_position = room_position + viewport_size / 2.0
    is_transitioning = true
```

Room boundaries are detected with `Area2D` triggers placed at room edges:

```gdscript
# room_trigger.gd
extends Area2D

@export var room_position: Vector2  # Top-left corner of the room

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        var camera = body.get_node("Camera2D") as Camera2D
        if camera and camera.has_method("transition_to_room"):
            camera.transition_to_room(room_position)
```

#### Option C: Scrolling Camera with Limits (Recommended for Prototypes)

Keep Camera2D as a child of the player with position smoothing enabled, and set hard limits matching the TileMap bounds:

```gdscript
# camera_setup.gd — call once when loading a map
func setup_camera_limits(camera: Camera2D, tilemap: TileMap) -> void:
    var map_rect = tilemap.get_used_rect()
    var tile_size = tilemap.tile_set.tile_size
    camera.limit_left = map_rect.position.x * tile_size.x
    camera.limit_top = map_rect.position.y * tile_size.y
    camera.limit_right = map_rect.end.x * tile_size.x
    camera.limit_bottom = map_rect.end.y * tile_size.y
```

---

## 3. Scene Structure

### 3.1 Player Scene

```
Player (CharacterBody2D)
├── AnimatedSprite2D          # Or Sprite2D + AnimationPlayer
├── CollisionShape2D          # Capsule or circle for physics body
├── HurtBox (Area2D)          # Instance of hurtbox.tscn
│   └── CollisionShape2D     # Slightly smaller than body collision
├── SwordHitBox (HitBox)      # Instance of hitbox.tscn
│   └── CollisionShape2D     # Positioned in front of player, disabled by default
├── InteractionArea (Area2D)  # For talking to NPCs, opening chests
│   └── CollisionShape2D
├── AnimationPlayer           # If using AnimationPlayer approach
├── AnimationTree             # State machine for animation blending
└── Camera2D                  # Follows player
```

**AnimatedSprite2D vs Sprite2D + AnimationPlayer:**

| Approach | Pros | Cons | Best For |
|----------|------|------|----------|
| AnimatedSprite2D | Simple setup, frame-based | Cannot animate other properties (collision shapes, positions) | Simple sprites, prototyping |
| Sprite2D + AnimationPlayer | Can animate ANY property (flip, position, collision enable/disable) | More setup overhead | Production games, attack animations |
| AnimationTree on top | State machine for transitions, blend spaces for directions | Most complex setup | Directional movement + attack combos |

**Recommendation**: Use `AnimationPlayer` (with a `Sprite2D` or `AnimatedSprite2D`) plus `AnimationTree` with a state machine. The AnimationPlayer gives you the power to toggle collision shapes during attack frames, and the AnimationTree manages state transitions cleanly.

### 3.2 Enemy Scene Structure

```
Slime (CharacterBody2D)
├── AnimatedSprite2D
├── CollisionShape2D           # Physics body
├── HurtBox (hurtbox.tscn)     # Receives damage from player
│   └── CollisionShape2D
├── ContactHitBox (hitbox.tscn) # Deals contact damage to player
│   └── CollisionShape2D
├── DetectionZone (Area2D)     # Large circle for player detection
│   └── CollisionShape2D
├── NavigationAgent2D          # Pathfinding for patrol/chase
└── AnimationPlayer            # Or AnimatedSprite2D
```

Each enemy type is its own scene that can be instanced into the world. Use a base script with `class_name BaseEnemy` and extend it for specific enemies:

```gdscript
# base_enemy.gd
class_name BaseEnemy
extends CharacterBody2D

@export var max_health: int = 3
@export var speed: float = 40.0
@export var knockback_force: float = 150.0

var health: int

func _ready() -> void:
    health = max_health
    add_to_group("enemies")

func take_damage(amount: int) -> void:
    health -= amount
    if health <= 0:
        die()
    else:
        hurt()

func die() -> void:
    # Override in subclass for custom death behavior
    queue_free()

func hurt() -> void:
    # Override for hurt animation/knockback
    pass
```

### 3.3 World/Map Organization

#### Approach A: Single TileMap with Multiple Layers (Recommended for Small-Medium Maps)

One large `TileMap` scene with layers for ground, walls, decoration:

```
World (Node2D)
├── TileMap
│   ├── Layer 0: Ground        # Grass, dirt, water
│   ├── Layer 1: Walls         # Collision-enabled tiles
│   └── Layer 2: Decoration    # Trees, rocks (above player)
├── Enemies (Node2D)           # Container for enemy instances
│   ├── Slime
│   ├── Slime2
│   └── Bat
├── Pickups (Node2D)
│   ├── Heart
│   └── Key
├── Interactions (Node2D)
│   ├── NPC
│   └── Chest
└── NavigationRegion2D         # Navigation mesh for enemy pathfinding
    └── (covers walkable area)
```

#### Approach B: Room-Based Scenes (Recommended for Zelda-Style)

Each room/screen is its own scene, loaded/instanced by a world manager:

```
World (Node2D)
├── CurrentRoom (loaded scene)
│   ├── TileMap
│   ├── Enemies
│   └── Pickups
└── Player
```

```gdscript
# world_manager.gd
extends Node2D

var current_room: Node2D = null

@onready var player: CharacterBody2D = $Player

func load_room(room_path: String, spawn_position: Vector2) -> void:
    if current_room:
        current_room.queue_free()

    var room_scene = load(room_path) as PackedScene
    current_room = room_scene.instantiate()
    add_child(current_room)
    move_child(current_room, 0)  # Behind player

    player.global_position = spawn_position
```

### 3.4 Screen Transitions

For transitions between rooms/areas, use an `AnimationPlayer` on a `CanvasLayer` with a `ColorRect` for fade effects:

```gdscript
# transition_manager.gd (Autoload)
extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal transition_midpoint  # Emitted at peak of fade-out

func transition(callable: Callable) -> void:
    animation_player.play("fade_out")
    await animation_player.animation_finished
    transition_midpoint.emit()
    callable.call()  # Load new room, move player, etc.
    animation_player.play("fade_in")
    await animation_player.animation_finished
```

The `ColorRect` covers the full screen, and the animations tween its `modulate.a` from 0 to 1 (fade out) and 1 to 0 (fade in).

---

## 4. Animation System

### 4.1 Recommended Approach: AnimationPlayer + AnimationTree

For a top-down RPG with 4-directional sprites, the recommended stack is:

1. **Sprite2D** (or AnimatedSprite2D) displays the current frame
2. **AnimationPlayer** defines all animation clips (idle_down, idle_up, walk_left, attack_right, etc.)
3. **AnimationTree** with `AnimationNodeStateMachine` manages transitions between states, using `BlendSpace2D` nodes for directional blending

### 4.2 AnimationTree Setup

```
AnimationTree
└── StateMachine (AnimationNodeStateMachine)
    ├── idle (BlendSpace2D)        # 4 directional idle animations
    ├── walk (BlendSpace2D)        # 4 directional walk animations
    ├── attack (BlendSpace2D)      # 4 directional attack animations
    └── hurt (AnimationNodeAnimation) # Single hurt animation
```

Each `BlendSpace2D` maps a 2D blend position to directional animations:

```
BlendSpace2D "idle":
  (-1, 0) → idle_left
  (1, 0)  → idle_right
  (0, -1) → idle_up
  (0, 1)  → idle_down
```

Control from GDScript:

```gdscript
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine = animation_tree["parameters/playback"]

func update_animation_parameters(direction: Vector2) -> void:
    # Set blend position for ALL directional states
    animation_tree.set("parameters/idle/blend_position", direction)
    animation_tree.set("parameters/walk/blend_position", direction)
    animation_tree.set("parameters/attack/blend_position", direction)

func change_animation_state(state_name: String) -> void:
    state_machine.travel(state_name)
```

### 4.3 AnimatedSprite2D vs AnimationPlayer vs AnimationTree Comparison

| Feature | AnimatedSprite2D | AnimationPlayer | AnimationTree |
|---------|-----------------|-----------------|---------------|
| Frame-by-frame animation | Built-in | Via property tracks | Via AnimationPlayer |
| Animate non-sprite properties | No | Yes (any property) | Yes |
| State machine | No (manual code) | No (manual code) | Built-in |
| Blend spaces (directional) | No | No | Built-in |
| Transition rules | No | No | Built-in |
| Complexity | Low | Medium | High |
| Best use case | Prototypes, simple NPCs | Single entities with property animation | Player/enemies with directional states |

### 4.4 Code-Based State Machine (Alternative to AnimationTree)

For those who prefer explicit code control over visual state machines:

```gdscript
# state.gd — Base state class
class_name State
extends Node

var entity: CharacterBody2D

func enter() -> void:
    pass

func exit() -> void:
    pass

func process_physics(delta: float) -> void:
    pass

func process_input(event: InputEvent) -> void:
    pass
```

```gdscript
# state_machine.gd
class_name StateMachine
extends Node

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
    for child in get_children():
        if child is State:
            states[child.name.to_lower()] = child
            child.entity = owner

    if initial_state:
        current_state = initial_state
        current_state.enter()

func transition_to(state_name: String) -> void:
    var new_state = states.get(state_name.to_lower())
    if new_state == null or new_state == current_state:
        return

    current_state.exit()
    current_state = new_state
    current_state.enter()

func _physics_process(delta: float) -> void:
    current_state.process_physics(delta)

func _unhandled_input(event: InputEvent) -> void:
    current_state.process_input(event)
```

```gdscript
# idle_state.gd
extends State

func enter() -> void:
    entity.animation_tree.set("parameters/idle/blend_position", entity.last_direction)
    entity.state_machine_playback.travel("idle")

func process_physics(_delta: float) -> void:
    var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if direction != Vector2.ZERO:
        entity.get_node("StateMachine").transition_to("walk")

func process_input(event: InputEvent) -> void:
    if event.is_action_pressed("attack"):
        entity.get_node("StateMachine").transition_to("attack")
```

```gdscript
# walk_state.gd
extends State

func enter() -> void:
    entity.state_machine_playback.travel("walk")

func process_physics(_delta: float) -> void:
    var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

    if direction == Vector2.ZERO:
        entity.get_node("StateMachine").transition_to("idle")
        return

    entity.last_direction = direction
    entity.velocity = direction * entity.speed
    entity.animation_tree.set("parameters/walk/blend_position", direction)
    entity.move_and_slide()
```

```gdscript
# attack_state.gd
extends State

func enter() -> void:
    entity.velocity = Vector2.ZERO
    entity.animation_tree.set("parameters/attack/blend_position", entity.last_direction)
    entity.state_machine_playback.travel("attack")
    # Wait for attack animation to finish
    await entity.animation_tree.animation_finished
    entity.get_node("StateMachine").transition_to("idle")

func process_physics(_delta: float) -> void:
    pass  # No movement during attack
```

Player scene tree with code-based state machine:
```
Player (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── AnimationPlayer
├── AnimationTree
├── StateMachine (Node)
│   ├── Idle (State)
│   ├── Walk (State)
│   ├── Attack (State)
│   └── Hurt (State)
├── HurtBox
├── SwordHitBox
└── Camera2D
```

---

## 5. TileMap System

### 5.1 TileMap Node Overview (Godot 4)

In Godot 4, `TileMap` uses `TileSet` resources. A single TileMap node can have multiple layers (ground, walls, decoration). Each layer can have independent Z-index and collision settings.

### 5.2 Creating a TileSet

1. Add a `TileMap` node to your scene
2. In the Inspector, create a new `TileSet` resource
3. Set `Tile Size` (common: 16x16 or 32x32 pixels)
4. In the TileSet editor (bottom panel), add a texture source (your tileset PNG)
5. Split into individual tiles automatically or manually

### 5.3 Adding Physics (Collision) to Tiles

1. In the TileSet resource, add a **Physics Layer** (TileSet > Physics Layers > Add Element)
2. Set the physics layer's `collision_layer` (e.g., layer 1 = "world")
3. Select wall tiles in the TileSet editor
4. In the "Physics" panel, draw collision polygons on each wall tile

### 5.4 TileMap Layers

Configure multiple layers for visual depth:

| Layer | Name | Z-Index | Physics | Purpose |
|-------|------|---------|---------|---------|
| 0 | Ground | -1 | No | Grass, dirt, paths |
| 1 | Walls | 0 | Yes (layer 1) | Walls, fences, cliffs |
| 2 | Above | 2 | No | Tree canopies, roof overhangs (drawn above player) |

### 5.5 Terrain Auto-Tiling

Terrains automate tile placement for edges, corners, and transitions. Setup:

1. In the TileSet editor, go to **Terrains** tab
2. Create a **Terrain Set** (e.g., "Ground")
   - Mode: `Match Corners and Sides` (most common for top-down)
3. Create **Terrains** within the set (e.g., "Grass", "Dirt", "Water")
4. Assign colors to each terrain
5. For each tile, paint the **Peering Bits** to define which terrain it connects to

**Peering Bits** tell the auto-tiler which neighboring tiles this tile expects. When painting, Godot automatically selects the correct tile variant based on surrounding terrain.

**Painting workflow:**
1. Select the TileMap node in the scene
2. Switch to the **Terrains** tab in the bottom toolbar
3. Select a terrain and paint on the map
4. Godot auto-places correct edge/corner tiles

### 5.6 Navigation on TileMap

For enemy pathfinding, add a navigation layer to the TileSet:

1. In TileSet, add a **Navigation Layer** (TileSet > Navigation Layers > Add Element)
2. For walkable tiles, draw navigation polygons covering the walkable area
3. Add a `NavigationRegion2D` to your scene that references the TileMap
4. Enemies use `NavigationAgent2D` to pathfind on the baked navigation mesh

---

## 6. Common Patterns

### 6.1 Hitbox/Hurtbox Pattern (Summary)

```
HitBox (Area2D):
  - collision_layer = dedicated hitbox layer
  - collision_mask = 0
  - monitoring = false
  - monitorable = true
  - Carries damage data (@export var damage)

HurtBox (Area2D):
  - collision_layer = 0
  - collision_mask = hitbox layer
  - monitoring = true
  - monitorable = false
  - Connects area_entered signal
  - Calls owner.take_damage(hitbox.damage)
```

This one-directional pattern prevents double-detection and is the standard in the Godot community.

### 6.2 State Machine Pattern

Two approaches, both valid:

**A. Code-based state machine** (see Section 4.4): Each state is a `Node` child with `enter()`, `exit()`, `process_physics()` methods. The `StateMachine` node manages transitions. Best for complex game logic per state.

**B. AnimationTree state machine**: Visual graph in the editor. Best when states map 1:1 to animations. Use `travel()` to transition, `get_current_node()` to query current state.

**When to use which:**
- Player with complex input handling per state → Code-based
- Enemy with simple patrol/chase/attack → Either works
- Purely animation-driven states → AnimationTree

### 6.3 Signal-Based Communication

Godot's signal system enables loose coupling between nodes. Key principles:

```gdscript
# RULE: Signal UP, call DOWN
# Parent nodes connect to children's signals
# Children call methods on children (not upward)

# Define custom signals
signal health_changed(new_health: int)
signal died

# Emit from the entity
func take_damage(amount: int) -> void:
    health -= amount
    health_changed.emit(health)
    if health <= 0:
        died.emit()

# Connect in parent or via editor
func _ready() -> void:
    player.health_changed.connect(_on_player_health_changed)
    player.died.connect(_on_player_died)
```

### 6.4 Autoloads for Global State

Register autoloads in Project > Project Settings > Autoload.

#### Events Bus (Signal Bus)

```gdscript
# events.gd — Autoload name: "Events"
extends Node

# Player signals
signal player_health_changed(health: int)
signal player_died

# Game flow signals
signal room_changed(room_name: String)
signal game_paused
signal game_resumed

# Enemy signals
signal enemy_defeated(enemy_type: String, position: Vector2)
```

Usage anywhere in the project:

```gdscript
# Emit from any script
Events.player_health_changed.emit(health)
Events.enemy_defeated.emit("slime", global_position)

# Connect from any script
func _ready() -> void:
    Events.player_health_changed.connect(_update_health_bar)
    Events.enemy_defeated.connect(_on_enemy_defeated)
```

#### Game Manager

```gdscript
# game_manager.gd — Autoload name: "GameManager"
extends Node

var player_health: int = 6
var player_max_health: int = 6
var keys_collected: int = 0
var current_room: String = ""

func reset_game() -> void:
    player_health = player_max_health
    keys_collected = 0
    current_room = ""

func add_key() -> void:
    keys_collected += 1
    Events.player_health_changed.emit(player_health)

func damage_player(amount: int) -> void:
    player_health = max(0, player_health - amount)
    Events.player_health_changed.emit(player_health)
    if player_health <= 0:
        Events.player_died.emit()
```

#### Audio Manager

```gdscript
# audio_manager.gd — Autoload name: "AudioManager"
extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_pool: Array[AudioStreamPlayer] = []

const MAX_SFX_PLAYERS = 8

func _ready() -> void:
    for i in MAX_SFX_PLAYERS:
        var player = AudioStreamPlayer.new()
        add_child(player)
        sfx_pool.append(player)

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
    for player in sfx_pool:
        if not player.playing:
            player.stream = stream
            player.volume_db = volume_db
            player.play()
            return

func play_music(stream: AudioStream, fade_duration: float = 1.0) -> void:
    var tween = create_tween()
    tween.tween_property(music_player, "volume_db", -40.0, fade_duration)
    await tween.finished
    music_player.stream = stream
    music_player.play()
    tween = create_tween()
    tween.tween_property(music_player, "volume_db", 0.0, fade_duration)
```

### 6.5 Resource Pattern for Data

Use custom `Resource` classes for game data (items, enemy stats):

```gdscript
# enemy_data.gd
class_name EnemyData
extends Resource

@export var name: String = ""
@export var max_health: int = 3
@export var speed: float = 40.0
@export var damage: int = 1
@export var experience_value: int = 5
@export var sprite_frames: SpriteFrames
```

Create `.tres` files in the editor for each enemy type and assign them:

```gdscript
# In enemy script
@export var data: EnemyData

func _ready() -> void:
    health = data.max_health
    $AnimatedSprite2D.sprite_frames = data.sprite_frames
```

---

## 7. Minimum Viable Prototype Scope

### What You Need for a Playable Zelda-Like Prototype

The goal is the smallest set of features that produces a recognizable Zelda-like gameplay loop: explore, fight, collect, progress.

#### MVP Feature Checklist

**Must Have (Week 1-2):**

- [ ] **Player movement** — 4/8-directional top-down movement with CharacterBody2D
- [ ] **Player animations** — Idle and walk in 4 directions (8 animation clips minimum)
- [ ] **Sword attack** — Melee attack with hitbox, 4-directional attack animation
- [ ] **1 enemy type** — Slime with patrol and chase AI, takes damage, dies
- [ ] **Collision** — Player and enemies collide with walls, cannot pass through
- [ ] **Health system** — Player and enemies have health, take damage, die
- [ ] **1 tilemap** — Ground + walls, at minimum a 3-4 room area
- [ ] **Basic HUD** — Health display (hearts)
- [ ] **Camera** — Follows player, stays within map bounds

**Should Have (Week 3):**

- [ ] **Knockback** — Player and enemies pushed back on hit
- [ ] **Invincibility frames** — Brief period after taking damage where entity cannot be hit again
- [ ] **Heart pickup** — Dropped by enemies or found in grass, restores health
- [ ] **Screen transitions** — Fade or scroll between rooms/areas
- [ ] **1 interaction** — Sign or NPC with dialogue box

**Nice to Have (Week 4+):**

- [ ] **Key + locked door** — Simple progression gate
- [ ] **Chest** — Open to receive item
- [ ] **Sound effects** — Sword swing, hit, pickup, enemy death
- [ ] **Background music** — 1 looping track
- [ ] **Death/respawn** — Game over screen, restart
- [ ] **Grass cutting** — Destructible environment, drops items

#### What to Explicitly EXCLUDE from MVP

- Inventory system
- Multiple weapons/items
- Saving/loading
- Multiple enemy types
- Boss fights
- Dialogue trees / quest system
- Shops / currency
- Crafting
- Minimap
- Multiple areas/dungeons
- Particle effects
- Screen shake / juice

### Recommended Build Order

1. **Player movement + collision** — Get a player moving in a walled room
2. **Sword attack animation** — Add attack with visible animation (no damage yet)
3. **Hitbox/hurtbox system** — Wire up damage dealing and receiving
4. **Enemy (slime)** — Static enemy that takes damage and dies
5. **Enemy AI** — Patrol and chase behavior
6. **Contact damage** — Enemy damages player on touch
7. **Health + HUD** — Hearts display, death condition
8. **TileMap** — Replace placeholder walls with a proper tilemap
9. **Camera** — Follow camera with limits
10. **Polish** — Knockback, i-frames, pickups, transitions

### Estimated Scope

| Component | Scenes | Scripts | Estimated Effort |
|-----------|--------|---------|-----------------|
| Player | 1 | 2-5 (depending on state machine approach) | 3-4 hours |
| Enemy (slime) | 1 | 1-2 | 2-3 hours |
| Hitbox/Hurtbox | 2 | 2 | 1 hour |
| TileMap + World | 1-4 | 0-1 | 2-3 hours |
| HUD | 1 | 1 | 1-2 hours |
| Camera | 0 (child of player) | 0-1 | 30 min |
| Autoloads | 0 | 2-3 | 1-2 hours |
| **Total MVP** | **6-9** | **8-15** | **~12-16 hours** |

---

## Sources

### Official Documentation
- [Godot Engine Documentation — CharacterBody2D Movement](https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html)
- [Godot Engine Documentation — 2D Movement Overview](https://docs.godotengine.org/en/stable/tutorials/2d/2d_movement.html)
- [Godot Engine Documentation — Using TileSets](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html)
- [Godot Engine Documentation — Using TileMaps](https://docs.godotengine.org/en/latest/tutorials/2d/using_tilemaps.html)
- [Godot Engine Documentation — AnimationTree](https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html)
- [Godot Engine Documentation — AnimationNodeStateMachine](https://docs.godotengine.org/en/stable/classes/class_animationnodestatemachine.html)
- [Godot Engine Documentation — Camera2D](https://docs.godotengine.org/en/stable/classes/class_camera2d.html)
- [Godot Engine Documentation — Singletons (Autoload)](https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html)
- [Godot Engine Documentation — Autoloads vs Internal Nodes](https://docs.godotengine.org/en/stable/tutorials/best_practices/autoloads_versus_internal_nodes.html)
- [Godot Engine Documentation — Physics Introduction](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html)

### Tutorials and Guides
- [GDQuest — Hitbox/Hurtbox Pattern for Godot 4](https://www.gdquest.com/library/hitbox_hurtbox_godot4/)
- [GDQuest — Events Bus Singleton Pattern](https://www.gdquest.com/tutorial/godot/design-patterns/event-bus-singleton/)
- [GDQuest — Hitbox/Hurtbox Demo (GitHub)](https://github.com/gdquest-demos/godot-4-hitbox-hurtbox)
- [KidsCanCode — AnimationTree State Machine (Godot 4)](https://kidscancode.org/godot_recipes/4.x/animation/using_animation_sm/)
- [Let's Learn Godot 4 by Making an RPG (DEV.to)](https://dev.to/christinec_dev/lets-learn-godot-4-by-making-an-rpg-part-1-project-overview-setup-bgc)
- [NightQuestGames — Camera2D Follow Player](https://www.nightquestgames.com/how-to-make-the-2d-camera-follow-the-player-in-godot-4/)
- [Collision Layers and Masks in Godot 4](https://www.gotut.net/collision-layers-and-masks-in-godot-4/)
- [Collision Layers/Masks Organization Guide](https://uhiyama-lab.com/en/notes/godot/collision-layers-masks-organization/)
- [Terrain Auto-Tiling Setup Guide](https://uhiyama-lab.com/en/notes/godot/terrains-autotile-setup/)
- [NavigationAgent2D Pathfinding Guide](https://uhiyama-lab.com/en/notes/godot/navigation-agent2d/)

### Community Resources and Templates
- [vmarnauza/godot-rpg — Zelda-like RPG Example (GitHub)](https://github.com/vmarnauza/godot-rpg)
- [Godot Forum — 2D Top-Down Template](https://forum.godotengine.org/t/i-created-a-godot-template-for-2d-top-down-games/95350)
- [Top-Down Action RPG Template (Godot Asset Library)](https://godotengine.org/asset-library/asset/487)
- [Godot Forum — Action & Adventure RPG Tutorial Thread](https://forum.godotengine.org/t/make-a-2d-action-adventure-rpg-in-godot-4/52120)
- [2D Hitbox Godot Plugin (GitHub)](https://github.com/jv-vogler/2d-hitbox-godot-plugin)
