# Game Dev Concepts for Software Engineers

Game development uses patterns that differ fundamentally from backend, data, or web engineering. This reference bridges the gap — explaining each concept in terms a software engineer already understands.

## The Game Loop

Unlike request-response or ETL pipelines, games run a continuous loop every frame (~60fps):

```
Input → Update → Render → repeat
```

Everything happens inside `_process(delta)` (visuals, UI) or `_physics_process(delta)` (movement, collisions). There's no "wait for request" — the engine calls your code every frame whether anything changed or not.

**Engineer analogy:** Think of it like a real-time stream processor that runs at 60 events/second, where every event is "one frame of game time."

## Delta Time

`delta` is the time elapsed since the last frame (in seconds). All movement and time-dependent logic must multiply by `delta` to be frame-rate independent:

```gdscript
# Without delta: moves 5 pixels per FRAME (speed depends on FPS)
position.x += 5

# With delta: moves 5 pixels per SECOND (consistent on any hardware)
position.x += 5 * delta
```

**Engineer analogy:** It's like normalizing throughput by wall-clock time instead of counting raw events.

## State Machines

The most important pattern in game dev. Nearly everything has states:

- **Player:** idle, walking, attacking, hurt, dead
- **Enemy AI:** idle, patrol, chase, attack, flee
- **Game flow:** menu, playing, paused, game_over, cutscene

In Godot prototypes, implement as `enum + match`:

```gdscript
enum State { IDLE, CHASE, ATTACK, HURT, DEAD }
var current_state: State = State.IDLE

func _physics_process(delta: float) -> void:
    match current_state:
        State.IDLE: _process_idle(delta)
        State.CHASE: _process_chase(delta)
```

**Engineer analogy:** Finite state machines, exactly like workflow engines or protocol handlers. Each state has entry/exit logic and valid transitions.

## The Scene Tree

Godot's hierarchy is not just organization — it determines:

- **Update order:** parent processes before children
- **Draw order:** later siblings draw on top of earlier ones
- **Transform inheritance:** a child moves/rotates with its parent
- **Lifetime:** freeing a parent frees all children

```
Player (CharacterBody2D)
├── Sprite2D          ← moves with player automatically
├── CollisionShape2D  ← moves with player automatically
└── Camera2D          ← follows player automatically
```

**Engineer analogy:** It's a DOM tree where CSS transforms cascade, but for game objects in 2D/3D space.

## Signals (Observer Pattern)

Godot's native event system. Nodes emit signals, other nodes connect to them:

```gdscript
# Emitter
signal health_changed(current: int, maximum: int)
health_changed.emit(hp, max_hp)

# Listener (connected in _ready)
player.health_changed.connect(_on_player_health_changed)
```

**Engineer analogy:** Pub/sub or event-driven architecture. Signals decouple producers from consumers — the emitter doesn't know or care who's listening.

## Collision Layers vs Masks

Every physics body has two bitmasks:

- **Layer:** "what am I?" (what layer this object occupies)
- **Mask:** "what do I detect?" (what layers this object scans for)

Collision happens when object A's **mask** includes object B's **layer** (OR vice versa).

```
Player body:  layer=2, mask=1        → "I am a player, I detect walls"
Enemy body:   layer=4, mask=1        → "I am an enemy, I detect walls"
Player sword: layer=8, mask=0        → "I am a hitbox, I detect nothing" (passive)
Enemy hurtbox: layer=0, mask=8       → "I have no layer, I detect player sword"
```

**Engineer analogy:** It's like security groups / firewall rules. Layer = "inbound tag", mask = "outbound filter."

**Common mistake:** Layer N is NOT bitmask value N. Layer 3 = bitmask value `4` (2^(N-1)). Layer 1+3 together = bitmask `5` (1+4).

## Core Loop (Game Design)

The repeating cycle that keeps players engaged:

```
explore → fight → loot → upgrade → explore (harder area) → ...
```

Every successful game has a clear core loop. If the loop isn't fun at its simplest, no amount of content fixes it. This is why "find the fun" is the first priority — validate the loop before building systems around it.

**Engineer analogy:** Think of it as the critical path in your system. If the critical path has bad latency, optimizing side paths doesn't help.

## "Juice" (Game Feel)

The feedback that makes actions feel satisfying:

- **Screen shake** on impact
- **Hit pause** (freeze 1-2 frames on heavy hits)
- **Particles** on explosions, footsteps, damage
- **Sound effects** on every player action
- **Camera smoothing** for fluid movement
- **Knockback** pushing enemies away on hit
- **Damage numbers** floating up from enemies
- **Invincibility blink** after taking damage

A game with perfect mechanics but no juice feels "dead." Adding juice is low-effort, high-impact — it's the difference between a prototype that feels like a homework assignment and one that feels like a game.

**Engineer analogy:** It's like UX polish — the difference between a CLI that just prints results and one with progress bars, colors, and confirmation messages. Same functionality, completely different experience.

## Frame-Based vs Async Thinking

Game code runs synchronously every frame. Long operations block rendering. This is fundamentally different from async/await patterns in web or data engineering:

```gdscript
# BAD: blocks rendering for 5 seconds
func _ready():
    OS.delay_msec(5000)  # game freezes

# GOOD: non-blocking wait
func _ready():
    await get_tree().create_timer(5.0).timeout  # game continues running
```

**Important:** `await` in `_physics_process()` does NOT block — it spawns a new coroutine every frame while previous ones are still suspended, causing "coroutine stacking" with duplicate side effects. Use timers or state flags instead.

**Engineer analogy:** It's like writing a tight event loop handler — you must return quickly from each callback or everything freezes.

## Resources vs Nodes

Godot has two core object types:

- **Nodes** are the "actors" — they exist in the scene tree, have position/rotation, process every frame. Think of them as running services.
- **Resources** are the "data" — they're shared, lightweight, and don't process. Think of them as config files or database records.

```
Node: Player, Enemy, Camera, AudioPlayer, Timer
Resource: Texture2D, AudioStream, SpriteFrames, Shape2D, Material
```

**Engineer analogy:** Nodes are running processes/containers. Resources are shared data/config that multiple processes can reference.
