extends CharacterBody2D

## Top-down 2D RPG Player Controller
## Features: 8-dir WASD movement, sword attack on mouse click, damage/knockback, i-frames, health (6 HP)

# Movement
@export var move_speed: float = 120.0

# Combat
@export var max_hp: int = 6
@export var attack_damage: int = 1
@export var attack_duration: float = 0.3
@export var attack_cooldown: float = 0.15
@export var hitbox_offset: float = 24.0
@export var hitbox_size: Vector2 = Vector2(28, 28)

# Knockback
@export var knockback_strength: float = 200.0
@export var knockback_friction: float = 800.0

# Invincibility
@export var invincibility_duration: float = 1.0
@export var flash_interval: float = 0.1

# State
var hp: int = max_hp
var facing_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var can_attack: bool = true
var is_invincible: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO

# Node references
var hitbox_area: Area2D = null
var hitbox_collision: CollisionShape2D = null
var sprite: Sprite2D = null
var invincibility_timer: Timer = null
var attack_timer: Timer = null
var attack_cooldown_timer: Timer = null
var flash_timer: Timer = null

# Signals
signal health_changed(current_hp: int, maximum_hp: int)
signal player_died


func _ready() -> void:
	hp = max_hp

	_create_hitbox()
	_create_timers()

	# Grab existing sprite if present, otherwise create a placeholder
	sprite = get_node_or_null("Sprite2D")
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)

	# Ensure player is on a collision layer enemies can detect
	# Layer 1 = Player, Layer 2 = Enemies, Layer 3 = Player Attack
	collision_layer = 1
	collision_mask = 2

	health_changed.emit(hp, max_hp)


func _physics_process(delta: float) -> void:
	var input_direction := _get_input_direction()

	if input_direction != Vector2.ZERO:
		facing_direction = input_direction.normalized()

	# Apply knockback friction
	if knockback_velocity.length() > 5.0:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	else:
		knockback_velocity = Vector2.ZERO

	# Movement (reduced during attack)
	var move_factor := 0.3 if is_attacking else 1.0
	velocity = (input_direction.normalized() * move_speed * move_factor) + knockback_velocity

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_try_attack()


func _get_input_direction() -> Vector2:
	var direction := Vector2.ZERO
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	# Fallback to raw key checks if input map actions are not configured
	if direction == Vector2.ZERO:
		if Input.is_key_pressed(KEY_A):
			direction.x -= 1.0
		if Input.is_key_pressed(KEY_D):
			direction.x += 1.0
		if Input.is_key_pressed(KEY_W):
			direction.y -= 1.0
		if Input.is_key_pressed(KEY_S):
			direction.y += 1.0

	return direction


# --- Attack System ---

func _try_attack() -> void:
	if is_attacking or not can_attack:
		return

	is_attacking = true
	can_attack = false

	# Position hitbox in the facing direction
	hitbox_area.position = facing_direction * hitbox_offset
	hitbox_area.visible = true
	hitbox_collision.set_deferred("disabled", false)

	# Deal damage to overlapping enemies after a short physics frame
	await get_tree().physics_frame
	_deal_damage_to_enemies()

	attack_timer.start(attack_duration)


func _deal_damage_to_enemies() -> void:
	if hitbox_area == null:
		return

	var overlapping := hitbox_area.get_overlapping_areas()
	for area in overlapping:
		var enemy := area.get_parent()
		if enemy.has_method("take_damage"):
			var direction := (enemy.global_position - global_position).normalized()
			enemy.take_damage(attack_damage, direction)

	var overlapping_bodies := hitbox_area.get_overlapping_bodies()
	for body in overlapping_bodies:
		if body.has_method("take_damage"):
			var direction := (body.global_position - global_position).normalized()
			body.take_damage(attack_damage, direction)


func _on_attack_timer_timeout() -> void:
	is_attacking = false
	hitbox_area.visible = false
	hitbox_collision.set_deferred("disabled", true)
	attack_cooldown_timer.start(attack_cooldown)


func _on_attack_cooldown_timeout() -> void:
	can_attack = true


# --- Damage System ---

func take_damage(amount: int, from_direction: Vector2 = Vector2.ZERO) -> void:
	if is_invincible or hp <= 0:
		return

	hp = clampi(hp - amount, 0, max_hp)
	health_changed.emit(hp, max_hp)

	# Apply knockback away from damage source
	if from_direction != Vector2.ZERO:
		knockback_velocity = from_direction.normalized() * knockback_strength
	else:
		knockback_velocity = -facing_direction * knockback_strength

	if hp <= 0:
		_die()
		return

	_start_invincibility()


func heal(amount: int) -> void:
	if hp <= 0:
		return

	hp = clampi(hp + amount, 0, max_hp)
	health_changed.emit(hp, max_hp)


func _start_invincibility() -> void:
	is_invincible = true
	invincibility_timer.start(invincibility_duration)
	flash_timer.start(flash_interval)


func _on_invincibility_timeout() -> void:
	is_invincible = false
	flash_timer.stop()
	if sprite:
		sprite.visible = true
		sprite.modulate.a = 1.0


func _on_flash_timeout() -> void:
	if sprite:
		sprite.visible = not sprite.visible


func _die() -> void:
	player_died.emit()
	# Disable further input processing; let the game world handle restart/game-over
	set_physics_process(false)
	set_process_unhandled_input(false)

	if sprite:
		# Simple death fade
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		await tween.finished

	queue_free()


# --- Node Creation Helpers ---

func _create_hitbox() -> void:
	hitbox_area = Area2D.new()
	hitbox_area.name = "SwordHitbox"
	hitbox_area.collision_layer = 4  # Layer 3 = Player Attack
	hitbox_area.collision_mask = 2   # Layer 2 = Enemies
	hitbox_area.monitoring = true
	hitbox_area.monitorable = false
	hitbox_area.visible = false
	add_child(hitbox_area)

	hitbox_collision = CollisionShape2D.new()
	hitbox_collision.name = "HitboxShape"
	var shape := RectangleShape2D.new()
	shape.size = hitbox_size
	hitbox_collision.shape = shape
	hitbox_collision.disabled = true
	hitbox_area.add_child(hitbox_collision)


func _create_timers() -> void:
	attack_timer = Timer.new()
	attack_timer.name = "AttackTimer"
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)

	attack_cooldown_timer = Timer.new()
	attack_cooldown_timer.name = "AttackCooldownTimer"
	attack_cooldown_timer.one_shot = true
	attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)
	add_child(attack_cooldown_timer)

	invincibility_timer = Timer.new()
	invincibility_timer.name = "InvincibilityTimer"
	invincibility_timer.one_shot = true
	invincibility_timer.timeout.connect(_on_invincibility_timeout)
	add_child(invincibility_timer)

	flash_timer = Timer.new()
	flash_timer.name = "FlashTimer"
	flash_timer.one_shot = false
	flash_timer.timeout.connect(_on_flash_timeout)
	add_child(flash_timer)
