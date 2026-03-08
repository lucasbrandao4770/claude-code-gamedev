extends CharacterBody2D
## Slime enemy with state machine AI.
## States: IDLE, WANDER, CHASE, HURT, DEAD.
## Wanders randomly when idle, chases the player on detection, deals
## continuous contact damage, and fades out on death.

signal died

enum State { IDLE, WANDER, CHASE, HURT, DEAD }

const DAMAGE_TICK_INTERVAL: float = 0.5

@export_category("Slime")

@export_group("Movement")
@export var wander_speed: float = 20.0
@export var chase_speed: float = 55.0
@export var wander_duration_min: float = 1.0
@export var wander_duration_max: float = 2.5
@export var idle_duration_min: float = 0.5
@export var idle_duration_max: float = 3.0

@export_group("Combat")
@export var max_hp: int = 3
@export var contact_damage: int = 1
@export var knockback_force: float = 120.0
@export var hurt_duration: float = 0.3
@export var death_fade_duration: float = 0.5

var hp: int
var current_state: State = State.IDLE
var player: Node2D = null
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var idle_timer: float = 0.0
var damage_tick_cooldown: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_zone: Area2D = $DetectionZone
@onready var contact_hitbox: Area2D = $ContactHitBox
@onready var hurt_box: Area2D = $HurtBox


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	idle_timer = randf_range(idle_duration_min, idle_duration_max)

	# Signal connections for detection zone (body-based, detects player CharacterBody2D)
	detection_zone.body_entered.connect(_on_detection_body_entered)
	detection_zone.body_exited.connect(_on_detection_body_exited)

	# Signal connection for receiving damage from player sword hitbox
	hurt_box.area_entered.connect(_on_hurtbox_area_entered)

	# Mark the contact hitbox so the player's hurtbox can identify it
	contact_hitbox.add_to_group("enemy_hitbox")


func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.WANDER:
			_process_wander(delta)
		State.CHASE:
			_process_chase(delta)
		State.HURT:
			# Decelerate during knockback
			velocity = velocity.lerp(Vector2.ZERO, 0.15)
			move_and_slide()
		State.DEAD:
			pass

	_process_contact_damage(delta)


func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return

	hp -= amount
	if hp <= 0:
		_die()
		return

	current_state = State.HURT
	sprite.modulate = Color(1, 0.3, 0.3)

	# Knockback away from player
	if player and is_instance_valid(player):
		velocity = (global_position - player.global_position).normalized() * knockback_force

	# Timer-based recovery (avoids await in _physics_process)
	var timer: SceneTreeTimer = get_tree().create_timer(hurt_duration)
	await timer.timeout

	if current_state == State.DEAD:
		return
	sprite.modulate = Color.WHITE
	current_state = State.CHASE if player != null else State.IDLE
	idle_timer = randf_range(idle_duration_min, idle_duration_max)


func get_damage() -> int:
	return contact_damage


# -- Private methods ----------------------------------------------------------

func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	idle_timer -= delta
	if idle_timer <= 0.0:
		wander_direction = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()
		wander_timer = randf_range(wander_duration_min, wander_duration_max)
		current_state = State.WANDER


func _process_wander(delta: float) -> void:
	velocity = wander_direction * wander_speed
	wander_timer -= delta

	if wander_timer <= 0.0:
		current_state = State.IDLE
		idle_timer = randf_range(idle_duration_min, idle_duration_max)

	move_and_slide()


func _process_chase(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		current_state = State.IDLE
		idle_timer = randf_range(idle_duration_min, idle_duration_max)
		return

	var direction: Vector2 = (player.global_position - global_position).normalized()
	velocity = direction * chase_speed
	move_and_slide()


func _process_contact_damage(delta: float) -> void:
	## Continuous contact damage: area_entered only fires once on overlap start,
	## so we also poll overlapping areas on a cooldown to re-apply damage while
	## the player stays in contact.
	if current_state == State.DEAD:
		return

	damage_tick_cooldown -= delta
	if damage_tick_cooldown > 0.0:
		return

	for area in contact_hitbox.get_overlapping_areas():
		if area.is_in_group("player_hurtbox") and area.get_parent().has_method("take_damage"):
			area.get_parent().take_damage(contact_damage, global_position)
			damage_tick_cooldown = DAMAGE_TICK_INTERVAL
			return


func _die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO

	# Disable all collision shapes so the corpse is inert
	$CollisionShape2D.set_deferred("disabled", true)
	contact_hitbox.set_deferred("monitoring", false)
	contact_hitbox.set_deferred("monitorable", false)
	hurt_box.set_deferred("monitoring", false)

	# Fade-out tween then free
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, death_fade_duration)
	await tween.finished

	died.emit()
	queue_free()


func _on_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		if current_state != State.HURT and current_state != State.DEAD:
			current_state = State.CHASE


func _on_detection_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = null
		if current_state == State.CHASE:
			current_state = State.IDLE
			idle_timer = randf_range(idle_duration_min, idle_duration_max)


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hitbox"):
		var damage: int = 1
		if area.get_parent().has_method("get_attack_damage"):
			damage = area.get_parent().get_attack_damage()
		take_damage(damage)
