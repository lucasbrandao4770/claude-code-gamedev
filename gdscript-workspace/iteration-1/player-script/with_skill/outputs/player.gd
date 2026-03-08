extends CharacterBody2D
## Top-down 2D RPG player with 8-direction movement, sword attack,
## damage/knockback, and invincibility frames.

signal health_changed(current: int, maximum: int)
signal died

enum State { IDLE, MOVE, ATTACK, HURT, DEAD }
enum Facing { DOWN, LEFT, RIGHT, UP }

const KNOCKBACK_DECAY: float = 600.0

@export_category("Player")

@export_group("Movement")
@export var speed: float = 120.0

@export_group("Combat")
@export_subgroup("Offense")
@export var attack_damage: int = 1
@export var attack_duration: float = 0.3
@export var hitbox_offset: float = 20.0
@export var hitbox_size: Vector2 = Vector2(18.0, 18.0)

@export_subgroup("Defense")
@export var max_hp: int = 6
@export var knockback_force: float = 200.0
@export var invincibility_duration: float = 1.0
@export var flash_interval: float = 0.1

var current_hp: int = 6
var current_state: State = State.IDLE
var facing: Facing = Facing.DOWN
var knockback_velocity: Vector2 = Vector2.ZERO
var _invincible: bool = false
var _damage_cooldown: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Area2D = $HurtBox
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)


func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.MOVE:
			_process_move(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HURT:
			_process_hurt(delta)
		State.DEAD:
			pass

	if _damage_cooldown > 0.0:
		_damage_cooldown -= delta

	if _damage_cooldown <= 0.0 and not _invincible:
		_check_overlapping_damage()


func _unhandled_input(event: InputEvent) -> void:
	if current_state == State.DEAD:
		return

	if event.is_action_pressed("attack") and current_state != State.ATTACK and current_state != State.HURT:
		_start_attack()


# -- Public methods ----------------------------------------------------------

func take_damage(amount: int, from_position: Vector2) -> void:
	if _invincible or current_state == State.DEAD:
		return

	current_hp = clampi(current_hp - amount, 0, max_hp)
	health_changed.emit(current_hp, max_hp)

	if current_hp <= 0:
		_enter_dead()
		return

	# Knockback direction: away from damage source
	knockback_velocity = (global_position - from_position).normalized() * knockback_force
	current_state = State.HURT
	_start_invincibility()


func heal(amount: int) -> void:
	if current_state == State.DEAD:
		return
	current_hp = clampi(current_hp + amount, 0, max_hp)
	health_changed.emit(current_hp, max_hp)


# -- Private methods ---------------------------------------------------------

func _process_idle(_delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		current_state = State.MOVE
		_update_facing(input_dir)

	velocity = Vector2.ZERO
	move_and_slide()


func _process_move(_delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_dir == Vector2.ZERO:
		current_state = State.IDLE
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_update_facing(input_dir)
	velocity = input_dir * speed
	move_and_slide()


func _process_attack(_delta: float) -> void:
	# Player is locked in place during attack; knockback still decays
	velocity = Vector2.ZERO
	move_and_slide()


func _process_hurt(delta: float) -> void:
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	velocity = knockback_velocity
	move_and_slide()

	if knockback_velocity.length() < 10.0:
		knockback_velocity = Vector2.ZERO
		current_state = State.IDLE


func _update_facing(direction: Vector2) -> void:
	# Choose the dominant axis for facing
	if absf(direction.x) >= absf(direction.y):
		facing = Facing.RIGHT if direction.x > 0.0 else Facing.LEFT
	else:
		facing = Facing.DOWN if direction.y > 0.0 else Facing.UP


func _start_attack() -> void:
	current_state = State.ATTACK
	_spawn_sword_hitbox()

	var timer: SceneTreeTimer = get_tree().create_timer(attack_duration)
	timer.timeout.connect(_on_attack_finished)


func _spawn_sword_hitbox() -> void:
	var hitbox := Area2D.new()
	hitbox.name = "SwordHitbox"
	hitbox.collision_layer = 0
	hitbox.collision_mask = 2  # Enemy hurtbox layer
	hitbox.add_to_group("player_hitbox")

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = hitbox_size
	shape.shape = rect
	hitbox.add_child(shape)

	# Position the hitbox in the facing direction
	var offset: Vector2 = _get_facing_vector() * hitbox_offset
	hitbox.position = offset

	add_child(hitbox)

	# Remove hitbox after attack duration
	var timer: SceneTreeTimer = get_tree().create_timer(attack_duration)
	timer.timeout.connect(hitbox.queue_free)

	# Deal damage to enemies already overlapping on next physics frame
	# (get_overlapping_areas needs one frame to populate)
	await get_tree().physics_frame
	if is_instance_valid(hitbox):
		for area: Area2D in hitbox.get_overlapping_areas():
			_apply_hit(area)

		# Also connect for enemies entering during the attack window
		hitbox.area_entered.connect(_apply_hit)


func _apply_hit(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox") and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(attack_damage, global_position)


func _on_attack_finished() -> void:
	if current_state == State.ATTACK:
		current_state = State.IDLE


func _get_facing_vector() -> Vector2:
	match facing:
		Facing.DOWN:
			return Vector2.DOWN
		Facing.UP:
			return Vector2.UP
		Facing.LEFT:
			return Vector2.LEFT
		Facing.RIGHT:
			return Vector2.RIGHT
	return Vector2.DOWN


func _start_invincibility() -> void:
	_invincible = true
	_damage_cooldown = invincibility_duration

	# Flash effect using a tween
	var tween: Tween = create_tween()
	var flash_count: int = int(invincibility_duration / flash_interval)
	for i: int in range(flash_count):
		tween.tween_property(sprite, "modulate:a", 0.3, flash_interval * 0.5)
		tween.tween_property(sprite, "modulate:a", 1.0, flash_interval * 0.5)

	tween.finished.connect(_on_invincibility_finished)


func _on_invincibility_finished() -> void:
	_invincible = false
	sprite.modulate.a = 1.0


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		take_damage(1, area.global_position)


func _check_overlapping_damage() -> void:
	for area: Area2D in hurtbox.get_overlapping_areas():
		if area.is_in_group("enemy_hitbox"):
			take_damage(1, area.global_position)
			return


func _enter_dead() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	died.emit()
	# Disable collision so player doesn't block anything
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
