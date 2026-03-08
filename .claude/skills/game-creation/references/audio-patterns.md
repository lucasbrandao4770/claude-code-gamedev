# Audio Patterns for Game Prototypes

Audio is the fastest way to make a prototype feel like a real game. This reference covers practical audio architecture for Godot 4.x prototypes.

## Node Types

| Node | Positional? | Use For |
|------|-------------|---------|
| `AudioStreamPlayer` | No (global) | Background music, menu sounds, UI clicks |
| `AudioStreamPlayer2D` | Yes (2D) | Sword swings, footsteps, enemy sounds, pickups |
| `AudioStreamPlayer3D` | Yes (3D) | Same as 2D but for 3D games |

**Rule of thumb:** If the sound comes from a specific location in the game world, use `AudioStreamPlayer2D`. If it's ambient or UI, use `AudioStreamPlayer`.

## Audio Bus Setup

Create separate buses from the start — it takes 30 seconds and saves hours later when the user wants volume sliders.

In the Godot editor's **Audio** tab (bottom panel):

```
Master
├── Music    (for background tracks)
├── SFX      (for game sound effects)
└── UI       (for menu clicks, dialog sounds)
```

Set the `bus` property on each AudioStreamPlayer to route it:

```gdscript
$Music.bus = "Music"
$SwordSound.bus = "SFX"
$ButtonClick.bus = "UI"
```

## Common Audio Architecture

### Background Music

Add a single `AudioStreamPlayer` as a child of the main scene or as an autoload:

```gdscript
# In game_world.gd or a MusicManager autoload
@onready var music: AudioStreamPlayer = $Music

func _ready() -> void:
    music.stream = preload("res://assets/audio/music/overworld.ogg")
    music.bus = "Music"
    music.volume_db = -10.0  # background level, not overpowering
    music.play()
```

**Looping:** Set `loop = true` on the AudioStream resource (not the player node). For `.ogg` files, enable looping in the import settings.

### Positional Sound Effects

Add `AudioStreamPlayer2D` as children of entities that make sounds:

```gdscript
# In player.gd
@onready var sword_sound: AudioStreamPlayer2D = $SwordSound
@onready var hurt_sound: AudioStreamPlayer2D = $HurtSound

func attack() -> void:
    sword_sound.play()

func take_damage(amount: int, from_position: Vector2) -> void:
    hurt_sound.play()
```

**Max distance:** Default is 2000px. For small game worlds (640x360 viewport), reduce to ~500px so sounds fade naturally:

```
[node name="SwordSound" type="AudioStreamPlayer2D" parent="."]
stream = ExtResource("3_sword_sfx")
bus = &"SFX"
max_distance = 500.0
```

### One-Shot Sound Effects

For sounds that play once and don't belong to a specific entity (e.g., UI clicks, pickup sounds), create a simple helper:

```gdscript
# Simple approach: just play() on the node
func _on_item_picked_up() -> void:
    $PickupSound.play()

# If the node might be freed while sound is playing,
# reparent the sound to the scene root first:
func _die() -> void:
    var death_sound := $DeathSound
    remove_child(death_sound)
    get_tree().current_scene.add_child(death_sound)
    death_sound.play()
    death_sound.finished.connect(death_sound.queue_free)
    queue_free()
```

## Scene Structure

```
GameWorld (Node2D)
├── Music (AudioStreamPlayer)           # background track
├── Player (CharacterBody2D)
│   ├── SwordSound (AudioStreamPlayer2D)
│   ├── HurtSound (AudioStreamPlayer2D)
│   └── FootstepSound (AudioStreamPlayer2D)
├── Enemies (Node2D)
│   └── Slime (CharacterBody2D)
│       ├── HitSound (AudioStreamPlayer2D)
│       └── DeathSound (AudioStreamPlayer2D)
└── HUD (CanvasLayer)
    └── UISound (AudioStreamPlayer)     # menu/dialog sounds
```

## Free Audio Sources

| Source | What They Have | License |
|--------|---------------|---------|
| [Kenney](https://kenney.nl/assets?q=audio) | UI sounds, RPG sounds, impacts | CC0 (public domain) |
| [OpenGameArt](https://opengameart.org/art-search-advanced?keys=&field_art_type_tid%5B%5D=13) | Music, SFX, ambient | Various (check per asset) |
| [Freesound](https://freesound.org/) | Huge SFX library | CC0/CC-BY (check per sound) |
| [itch.io](https://itch.io/game-assets/free/tag-music) | Chiptune music, SFX packs | Various |

For pixel art prototypes, **chiptune/8-bit style audio** matches the aesthetic best.

## .tscn Syntax for Audio Nodes

When adding audio nodes via Edit tool (MCP can't set streams):

```
[ext_resource type="AudioStream" path="res://assets/audio/sfx/sword.wav" id="3_sword"]
[ext_resource type="AudioStream" path="res://assets/audio/music/overworld.ogg" id="4_music"]

[node name="SwordSound" type="AudioStreamPlayer2D" parent="."]
stream = ExtResource("3_sword")
bus = &"SFX"
max_distance = 500.0

[node name="Music" type="AudioStreamPlayer" parent="."]
stream = ExtResource("4_music")
bus = &"Music"
volume_db = -10.0
autoplay = true
```

**Note:** `bus` uses StringName syntax in .tscn files: `bus = &"SFX"` (with the `&` prefix).

## Prototyping Tip

Don't over-engineer audio for a prototype. The minimum viable audio setup is:

1. One `AudioStreamPlayer` for background music (autoplay, looping)
2. One `AudioStreamPlayer2D` per entity for its most important sound (sword hit, enemy death)
3. Done. Add more sounds in polish phase.
