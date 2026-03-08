extends CharacterBody2D
## IA do Slime - inimigo basico das Whispering Glades.
## Estados: IDLE, WANDER, CHASE, HURT, DEAD.
## Docil: so persegue quando Kael esta muito perto.

enum State { IDLE, WANDER, CHASE, HURT, DEAD }

@export_group("Movimento")
@export var speed: float = 25.0
@export var chase_speed: float = 35.0

@export_group("Combate")
@export var max_hp: int = 3
@export var contact_damage: int = 1
@export var detection_radius: float = 48.0

# Sprite sheets: Idle=6col x 4row, Walk=8col x 4row (frames 64x64)
# Linhas: 0=baixo, 1=esquerda, 2=direita, 3=cima (convencao CraftPix)
const IDLE_SHEET = preload("res://assets/sprites/enemies/Slime1/With_shadow/Slime1_Idle_with_shadow.png")
const WALK_SHEET = preload("res://assets/sprites/enemies/Slime1/With_shadow/Slime1_Walk_with_shadow.png")
const IDLE_COLS := 6
const WALK_COLS := 8

const DIR_DOWN := 0
const DIR_LEFT := 1
const DIR_RIGHT := 2
const DIR_UP := 3

var hp: int
var current_state: State = State.IDLE
var player: Node2D = null
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var idle_timer: float = 0.0
var anim_frame: int = 0
var anim_timer: float = 0.0
var facing_row: int = DIR_DOWN

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_zone: Area2D = $DetectionZone
@onready var contact_hitbox: Area2D = $ContactHitBox
@onready var hurt_box: Area2D = $HurtBox


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	_setup_sprite()
	_setup_collision_shapes()
	_setup_collision_layers()
	current_state = State.IDLE
	idle_timer = randf_range(0.5, 2.0)


func _setup_sprite() -> void:
	sprite.texture = IDLE_SHEET
	sprite.hframes = 6
	sprite.vframes = 4
	sprite.frame = 0


func _setup_collision_shapes() -> void:
	# Corpo do slime
	var body_shape := CircleShape2D.new()
	body_shape.radius = 6.0
	$CollisionShape2D.shape = body_shape
	$CollisionShape2D.position = Vector2(0, 4)

	# Zona de deteccao
	var detect_shape := CircleShape2D.new()
	detect_shape.radius = detection_radius
	detection_zone.get_node("CollisionShape2D").shape = detect_shape

	# Hitbox de contato (dano por toque)
	var contact_shape := CircleShape2D.new()
	contact_shape.radius = 7.0
	contact_hitbox.get_node("CollisionShape2D").shape = contact_shape

	# Hurtbox (recebe dano da espada)
	var hurt_shape := CircleShape2D.new()
	hurt_shape.radius = 7.0
	hurt_box.get_node("CollisionShape2D").shape = hurt_shape


func _setup_collision_layers() -> void:
	# Corpo: layer 3 (enemies), mask 1 (world)
	collision_layer = 4
	collision_mask = 1

	# Zona de deteccao: detecta corpos no layer 2 (player)
	detection_zone.collision_layer = 0
	detection_zone.collision_mask = 2
	detection_zone.monitoring = true
	detection_zone.body_entered.connect(_on_detection_body_entered)
	detection_zone.body_exited.connect(_on_detection_body_exited)

	# Hitbox de contato: layer 5 (enemy_hitbox)
	contact_hitbox.collision_layer = 16
	contact_hitbox.collision_mask = 0
	contact_hitbox.monitoring = false
	contact_hitbox.monitorable = true
	contact_hitbox.add_to_group("enemy_hitbox")

	# Hurtbox: mask 4 (player_hitbox = layer 4 = bit 8)
	hurt_box.collision_layer = 0
	hurt_box.collision_mask = 8
	hurt_box.monitoring = true
	hurt_box.monitorable = false
	hurt_box.area_entered.connect(_on_hurtbox_area_entered)


func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.WANDER:
			_process_wander(delta)
		State.CHASE:
			_process_chase(delta)
		State.HURT:
			velocity = velocity.lerp(Vector2.ZERO, 0.15)
			move_and_slide()
		State.DEAD:
			pass

	_animate(delta)


func _process_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	idle_timer -= delta
	if idle_timer <= 0:
		wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		wander_timer = randf_range(1.0, 2.5)
		current_state = State.WANDER


func _process_wander(delta: float) -> void:
	velocity = wander_direction * speed
	wander_timer -= delta

	if wander_timer <= 0:
		current_state = State.IDLE
		idle_timer = randf_range(1.0, 3.0)

	_update_facing(velocity)
	move_and_slide()


func _process_chase(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		current_state = State.IDLE
		idle_timer = 1.0
		return

	var dir := (player.global_position - global_position).normalized()
	velocity = dir * chase_speed
	_update_facing(velocity)
	move_and_slide()


func _update_facing(vel: Vector2) -> void:
	if vel.length() < 0.1:
		return
	if abs(vel.x) > abs(vel.y):
		facing_row = DIR_RIGHT if vel.x > 0 else DIR_LEFT
	else:
		facing_row = DIR_DOWN if vel.y > 0 else DIR_UP


func _animate(delta: float) -> void:
	if current_state == State.DEAD:
		return

	var is_moving := velocity.length() > 1.0
	var target_sheet: Texture2D = WALK_SHEET if is_moving else IDLE_SHEET
	var cols: int = WALK_COLS if is_moving else IDLE_COLS

	if sprite.texture != target_sheet:
		sprite.texture = target_sheet
		sprite.hframes = cols
		sprite.vframes = 4
		anim_frame = 0

	anim_timer += delta
	if anim_timer >= 0.15:
		anim_timer = 0.0
		anim_frame = (anim_frame + 1) % cols
		sprite.frame = facing_row * cols + anim_frame


func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		_die()
		return

	current_state = State.HURT
	sprite.modulate = Color(1, 0.3, 0.3)

	# Knockback na direcao oposta ao jogador
	if player and is_instance_valid(player):
		velocity = (global_position - player.global_position).normalized() * 120

	await get_tree().create_timer(0.3).timeout
	sprite.modulate = Color.WHITE
	current_state = State.CHASE if player != null else State.IDLE
	idle_timer = 1.0


func _die() -> void:
	current_state = State.DEAD
	sprite.modulate = Color(1, 1, 1, 0.4)

	# Desativa todas as colisoes
	$CollisionShape2D.set_deferred("disabled", true)
	contact_hitbox.set_deferred("monitoring", false)
	hurt_box.set_deferred("monitoring", false)

	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()


func get_damage() -> int:
	return contact_damage


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
			idle_timer = 1.0


func _on_hurtbox_area_entered(_area: Area2D) -> void:
	take_damage(1)
