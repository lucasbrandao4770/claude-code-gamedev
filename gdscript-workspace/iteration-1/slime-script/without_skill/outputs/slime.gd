extends CharacterBody2D
## Slime enemy with idle wandering, player chasing, contact damage, and fade-out death.
## Requires the following node structure:
##   CharacterBody2D (this script)
##   ├─ AnimatedSprite2D (or Sprite2D) — visuals
##   ├─ CollisionShape2D — physics body
##   ├─ DetectionZone (Area2D) — player detection radius
##   │   └─ CollisionShape2D
##   ├─ HurtBox (Area2D) — contact damage hitbox
##   │   └─ CollisionShape2D
##   └─ WanderTimer (Timer) — controls wander direction changes

enum State { IDLE, WANDER, CHASE, DEAD }

# -- Tuning constants --
@export var max_hp: int = 3
@export var wander_speed: float = 30.0
@export var chase_speed: float = 60.0
@export var contact_damage: int = 1
@export var damage_tick_interval: float = 0.5
@export var death_fade_duration: float = 0.6
@export var wander_time_min: float = 1.0
@export var wander_time_max: float = 3.0
@export var idle_time_min: float = 0.5
@export var idle_time_max: float = 2.0

# -- Runtime state --
var current_state: State = State.IDLE
var hp: int
var wander_direction: Vector2 = Vector2.ZERO
var target: CharacterBody2D = null  # reference to the player
var _damage_cooldowns: Dictionary = {}  # node_id -> remaining cooldown

# -- Node references (assigned in _ready) --
@onready var animated_sprite: Node = _find_sprite_node()
@onready var detection_zone: Area2D = $DetectionZone
@onready var hurt_box: Area2D = $HurtBox
@onready var wander_timer: Timer = $WanderTimer


func _ready() -> void:
	hp = max_hp

	# Configure wander timer
	wander_timer.one_shot = true
	wander_timer.timeout.connect(_on_wander_timer_timeout)

	# Detection zone signals
	detection_zone.body_entered.connect(_on_detection_zone_body_entered)
	detection_zone.body_exited.connect(_on_detection_zone_body_exited)

	# Start in idle with a brief pause before first wander
	_enter_idle()


func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.WANDER:
			velocity = wander_direction * wander_speed
		State.CHASE:
			if is_instance_valid(target):
				var direction: Vector2 = (target.global_position - global_position).normalized()
				velocity = direction * chase_speed
			else:
				# Lost target reference — go back to idle
				target = null
				_transition_to(State.IDLE)
				return
		State.DEAD:
			velocity = Vector2.ZERO

	if current_state != State.DEAD:
		move_and_slide()
		_update_facing()
		_process_contact_damage(delta)


# ---------------------------------------------------------------------------
# State machine helpers
# ---------------------------------------------------------------------------

func _transition_to(new_state: State) -> void:
	# Exit logic for old state
	match current_state:
		State.WANDER:
			wander_timer.stop()

	current_state = new_state

	# Enter logic for new state
	match new_state:
		State.IDLE:
			_enter_idle()
		State.WANDER:
			_enter_wander()
		State.CHASE:
			_enter_chase()
		State.DEAD:
			_enter_dead()


func _enter_idle() -> void:
	current_state = State.IDLE
	velocity = Vector2.ZERO
	_play_animation("idle")
	wander_timer.start(randf_range(idle_time_min, idle_time_max))


func _enter_wander() -> void:
	current_state = State.WANDER
	wander_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	_play_animation("walk")
	wander_timer.start(randf_range(wander_time_min, wander_time_max))


func _enter_chase() -> void:
	current_state = State.CHASE
	wander_timer.stop()
	_play_animation("walk")


func _enter_dead() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO

	# Disable all collision so the corpse doesn't block anything
	set_physics_process(false)
	if hurt_box:
		hurt_box.set_deferred("monitoring", false)
		hurt_box.set_deferred("monitorable", false)
	detection_zone.set_deferred("monitoring", false)
	collision_layer = 0
	collision_mask = 0

	# Fade-out tween then free
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, death_fade_duration)
	tween.tween_callback(queue_free)


# ---------------------------------------------------------------------------
# Detection zone callbacks
# ---------------------------------------------------------------------------

func _on_detection_zone_body_entered(body: Node2D) -> void:
	if current_state == State.DEAD:
		return
	if body.is_in_group("player"):
		target = body as CharacterBody2D
		_transition_to(State.CHASE)


func _on_detection_zone_body_exited(body: Node2D) -> void:
	if current_state == State.DEAD:
		return
	if body == target:
		target = null
		_transition_to(State.IDLE)


# ---------------------------------------------------------------------------
# Wander timer callback
# ---------------------------------------------------------------------------

func _on_wander_timer_timeout() -> void:
	if current_state == State.DEAD:
		return
	# If chasing, ignore the timer
	if current_state == State.CHASE:
		return

	# Alternate between idle and wander
	if current_state == State.IDLE:
		_transition_to(State.WANDER)
	else:
		_transition_to(State.IDLE)


# ---------------------------------------------------------------------------
# Contact damage
# ---------------------------------------------------------------------------

func _process_contact_damage(delta: float) -> void:
	# Tick down existing cooldowns
	var expired_keys: Array = []
	for key in _damage_cooldowns:
		_damage_cooldowns[key] -= delta
		if _damage_cooldowns[key] <= 0.0:
			expired_keys.append(key)
	for key in expired_keys:
		_damage_cooldowns.erase(key)

	if not hurt_box:
		return

	# Check overlapping bodies for continuous contact damage
	for body in hurt_box.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			var body_id: int = body.get_instance_id()
			if body_id not in _damage_cooldowns:
				body.take_damage(contact_damage)
				_damage_cooldowns[body_id] = damage_tick_interval


# ---------------------------------------------------------------------------
# Receiving damage
# ---------------------------------------------------------------------------

## Call this from the player's attack logic to hurt the slime.
func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return

	hp -= amount
	_flash_hit()

	if hp <= 0:
		_transition_to(State.DEAD)


func _flash_hit() -> void:
	# Brief white flash to indicate damage
	modulate = Color(3.0, 3.0, 3.0, 1.0)  # Bright flash
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)


# ---------------------------------------------------------------------------
# Animation / visual helpers
# ---------------------------------------------------------------------------

func _find_sprite_node() -> Node:
	# Prefer AnimatedSprite2D, fall back to Sprite2D
	for child in get_children():
		if child is AnimatedSprite2D:
			return child
		if child is Sprite2D:
			return child
	return null


func _play_animation(anim_name: String) -> void:
	if animated_sprite and animated_sprite is AnimatedSprite2D:
		if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.play(anim_name)


func _update_facing() -> void:
	if animated_sprite and velocity.length() > 0.1:
		animated_sprite.flip_h = velocity.x < 0.0
