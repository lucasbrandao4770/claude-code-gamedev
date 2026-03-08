extends CharacterBody2D
## Script principal do jogador Kael.
## Controla movimento 8-direcional, ataque com espada,
## sistema de dano com knockback e invencibilidade.

# --- Configuracao ---
@export_group("Movimento")
@export var speed: float = 80.0
@export var knockback_force: float = 150.0

@export_group("Combate")
@export var max_hp: int = 6
@export var attack_damage: int = 1
@export var attack_duration: float = 0.2
@export var hurt_duration: float = 0.4

# --- Sprite sheet config ---
# Idle: 12 colunas x 4 linhas (768x256, frames 64x64)
# Walk: 6 colunas x 4 linhas (384x256, frames 64x64)
# Linhas: 0=baixo, 1=esquerda, 2=direita, 3=cima (convencao CraftPix)
const IDLE_SHEET = preload("res://assets/sprites/player/Swordsman_lvl1/With_shadow/Swordsman_lvl1_Idle_with_shadow.png")
const WALK_SHEET = preload("res://assets/sprites/player/Swordsman_lvl1/With_shadow/Swordsman_lvl1_Walk_with_shadow.png")
const ATTACK_SHEET = preload("res://assets/sprites/player/Swordsman_lvl1/With_shadow/Swordsman_lvl1_attack_with_shadow.png")

const DIR_DOWN := 0
const DIR_LEFT := 1
const DIR_RIGHT := 2
const DIR_UP := 3

# --- Estado ---
var hp: int
var is_attacking: bool = false
var is_hurt: bool = false
var facing_row: int = DIR_DOWN
var anim_frame: int = 0
var anim_timer: float = 0.0
const IDLE_CYCLE_TIME := 1.44  # duracao total do ciclo idle (segundos)
const WALK_CYCLE_TIME := 0.72  # duracao total do ciclo walk
const ATTACK_CYCLE_TIME := 0.2 # duracao total do ataque (rapido)
var knockback_velocity: Vector2 = Vector2.ZERO

# --- Referencias ---
@onready var sprite: Sprite2D = $Sprite2D
@onready var sword_hitbox: Area2D = $SwordHitBox
@onready var hurt_box: Area2D = $HurtBox
@onready var camera: Camera2D = $Camera2D

# --- Sinais ---
signal health_changed(new_hp: int)
signal died


func _ready() -> void:
	hp = max_hp
	add_to_group("player")
	_setup_sprite()
	_setup_collision_shapes()
	_setup_collision_layers()
	camera.zoom = Vector2(2, 2)


func _setup_sprite() -> void:
	sprite.texture = IDLE_SHEET
	sprite.hframes = 12
	sprite.vframes = 4
	sprite.frame = 0


func _setup_collision_shapes() -> void:
	# Corpo do jogador
	var body_shape := RectangleShape2D.new()
	body_shape.size = Vector2(10, 10)
	$CollisionShape2D.shape = body_shape
	$CollisionShape2D.position = Vector2(0, 4)

	# Hitbox da espada
	var sword_shape := RectangleShape2D.new()
	sword_shape.size = Vector2(14, 8)
	sword_hitbox.get_node("CollisionShape2D").shape = sword_shape
	sword_hitbox.get_node("CollisionShape2D").disabled = true

	# Hurtbox do jogador
	var hurt_shape := RectangleShape2D.new()
	hurt_shape.size = Vector2(10, 12)
	hurt_box.get_node("CollisionShape2D").shape = hurt_shape


func _setup_collision_layers() -> void:
	# Corpo: layer 2 (player), mask 1 (world) + 4 (enemies)
	collision_layer = 2
	collision_mask = 1 | 4

	# Espada: layer 8 (player_hitbox)
	sword_hitbox.collision_layer = 8
	sword_hitbox.collision_mask = 0
	sword_hitbox.monitoring = false
	sword_hitbox.monitorable = true

	# Hurtbox: mask 16 (enemy_hitbox)
	hurt_box.collision_layer = 0
	hurt_box.collision_mask = 16
	hurt_box.monitoring = true
	hurt_box.monitorable = false
	hurt_box.area_entered.connect(_on_hurtbox_area_entered)


func _physics_process(delta: float) -> void:
	if is_hurt:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 0.2)
		move_and_slide()
		return

	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Movimento 8-direcional
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed
		_update_facing(direction)
		_animate_walk(delta)
	else:
		velocity = Vector2.ZERO
		_animate_idle(delta)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and not is_attacking and not is_hurt:
		_attack()
	if event.is_action_pressed("interact"):
		_try_interact()


func _update_facing(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		facing_row = DIR_RIGHT if direction.x > 0 else DIR_LEFT
	else:
		facing_row = DIR_DOWN if direction.y > 0 else DIR_UP


func _animate_idle(delta: float) -> void:
	if sprite.texture != IDLE_SHEET:
		sprite.texture = IDLE_SHEET
		sprite.hframes = 12
		sprite.vframes = 4
		anim_frame = 0

	# A linha UP so tem 4 frames, as demais tem 12
	var max_frames := 4 if facing_row == DIR_UP else 12
	var frame_time := IDLE_CYCLE_TIME / max_frames

	anim_timer += delta
	if anim_timer >= frame_time:
		anim_timer = 0.0
		anim_frame = (anim_frame + 1) % max_frames
		sprite.frame = facing_row * 12 + anim_frame


func _animate_walk(delta: float) -> void:
	if sprite.texture != WALK_SHEET:
		sprite.texture = WALK_SHEET
		sprite.hframes = 6
		sprite.vframes = 4
		anim_frame = 0

	var frame_time := WALK_CYCLE_TIME / 6.0

	anim_timer += delta
	if anim_timer >= frame_time:
		anim_timer = 0.0
		anim_frame = (anim_frame + 1) % 6
		sprite.frame = facing_row * 6 + anim_frame


func _attack() -> void:
	is_attacking = true

	# Troca para sprite de ataque
	sprite.texture = ATTACK_SHEET
	sprite.hframes = 8
	sprite.vframes = 4
	sprite.frame = facing_row * 8

	# Posiciona hitbox da espada na direcao que esta olhando
	var sword_col: CollisionShape2D = sword_hitbox.get_node("CollisionShape2D")
	match facing_row:
		DIR_DOWN:
			sword_col.position = Vector2(0, 14)
			sword_col.shape.size = Vector2(14, 8)
		DIR_UP:
			sword_col.position = Vector2(0, -14)
			sword_col.shape.size = Vector2(14, 8)
		DIR_LEFT:
			sword_col.position = Vector2(-14, 0)
			sword_col.shape.size = Vector2(8, 14)
		DIR_RIGHT:
			sword_col.position = Vector2(14, 0)
			sword_col.shape.size = Vector2(8, 14)

	# Ativa hitbox
	sword_col.disabled = false
	sword_hitbox.monitoring = true

	# Anima os frames do ataque
	var frame_time := ATTACK_CYCLE_TIME / 8.0
	for i in range(8):
		sprite.frame = facing_row * 8 + i
		await get_tree().create_timer(frame_time).timeout

	# Desativa hitbox
	sword_col.disabled = true
	sword_hitbox.monitoring = false

	is_attacking = false


func _try_interact() -> void:
	# Busca NPCs ou interagiveis na direcao que esta olhando
	var dir_vector := Vector2.ZERO
	match facing_row:
		DIR_DOWN: dir_vector = Vector2.DOWN
		DIR_UP: dir_vector = Vector2.UP
		DIR_LEFT: dir_vector = Vector2.LEFT
		DIR_RIGHT: dir_vector = Vector2.RIGHT

	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_position + dir_vector * 20
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var results := space.intersect_point(query, 1)
	if results.size() > 0:
		var collider = results[0].collider
		if collider.has_method("interact"):
			collider.interact()


func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO) -> void:
	if is_hurt:
		return

	hp -= amount
	health_changed.emit(hp)

	if hp <= 0:
		_die()
		return

	# Knockback e invencibilidade temporaria
	is_hurt = true
	if from_position != Vector2.ZERO:
		knockback_velocity = (global_position - from_position).normalized() * knockback_force

	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(hurt_duration).timeout
	sprite.modulate = Color.WHITE
	is_hurt = false


func _die() -> void:
	died.emit()
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)
	set_physics_process(false)
	set_process_unhandled_input(false)

	await get_tree().create_timer(2.0).timeout

	# Respawn
	hp = max_hp
	health_changed.emit(hp)
	sprite.modulate = Color.WHITE
	set_physics_process(true)
	set_process_unhandled_input(true)
	global_position = Vector2.ZERO


func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		var damage := 1
		if area.has_method("get_damage"):
			damage = area.get_damage()
		take_damage(damage, area.global_position)
