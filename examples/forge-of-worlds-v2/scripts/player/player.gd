## Controle do jogador — movimento, combate, dano e animação via sprite sheets.
extends CharacterBody2D

# Sinais para comunicação com HUD e GameManager
signal health_changed(current: int, maximum: int)
signal player_died

# Direções do sprite (ordem CraftPix: DOWN=0, LEFT=1, RIGHT=2, UP=3)
enum Direction { DOWN, LEFT, RIGHT, UP }

# Estados da máquina de estados
enum State { IDLE, WALK, ATTACK, HURT, DEAD }

# Sprite sheets — cada estado tem colunas/hframes diferentes
const SPRITE_IDLE: Texture2D = preload("res://assets/sprites/player/Swordsman_lvl1_Idle_with_shadow.png")
const SPRITE_WALK: Texture2D = preload("res://assets/sprites/player/Swordsman_lvl1_Walk_with_shadow.png")
const SPRITE_ATTACK: Texture2D = preload("res://assets/sprites/player/Swordsman_lvl1_attack_with_shadow.png")
const SPRITE_HURT: Texture2D = preload("res://assets/sprites/player/Swordsman_lvl1_Hurt_with_shadow.png")
const SPRITE_DEATH: Texture2D = preload("res://assets/sprites/player/Swordsman_lvl1_Death_with_shadow.png")

# Número de colunas (hframes) por estado
const HFRAMES_IDLE: int = 12
const HFRAMES_WALK: int = 6
const HFRAMES_ATTACK: int = 8
const HFRAMES_HURT: int = 5
const HFRAMES_DEATH: int = 7

# Número de linhas (vframes) — sempre 4 (DOWN, LEFT, RIGHT, UP)
const VFRAMES: int = 4

# Frames por linha do Idle (UP tem apenas 4 frames, demais têm 12)
const IDLE_FRAMES_PER_ROW: Array[int] = [12, 12, 12, 4]

@export_group("Movimento")
@export var speed: float = 120.0
@export var knockback_force: float = 200.0

@export_group("Combate")
@export var max_hp: int = 6
@export var attack_damage: int = 1
@export var hurt_duration: float = 0.3
@export var invincibility_duration: float = 1.0

@export_group("Animacao")
@export var idle_cycle: float = 1.0
@export var walk_cycle: float = 0.6
@export var attack_cycle: float = 0.4
@export var hurt_cycle: float = 0.4
@export var death_cycle: float = 0.8

# Referências aos nós filhos
@onready var sprite: Sprite2D = $Sprite2D
@onready var sword_hitbox: Area2D = $SwordHitBox
@onready var sword_collision: CollisionShape2D = $SwordHitBox/CollisionShape2D
@onready var hurt_box: Area2D = $HurtBox

# Estado interno
var hp: int
var current_state: State = State.IDLE
var facing: Direction = Direction.DOWN
var anim_timer: float = 0.0
var damage_cooldown: float = 0.0
var state_timer: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var blink_timer: float = 0.0


func _ready() -> void:
	hp = max_hp
	sword_collision.disabled = true
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)
	_switch_sprite_sheet(State.IDLE)
	health_changed.emit(hp, max_hp)


func _physics_process(delta: float) -> void:
	# Atualiza cooldown de invencibilidade
	if damage_cooldown > 0.0:
		damage_cooldown -= delta
		_update_blink(delta)
	else:
		sprite.modulate.a = 1.0

	# Máquina de estados
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.WALK:
			_process_walk(delta)
		State.ATTACK:
			_process_attack(delta)
		State.HURT:
			_process_hurt(delta)
		State.DEAD:
			_process_dead(delta)

	# Verifica dano por contato (overlapping) fora de estados protegidos
	if damage_cooldown <= 0.0 and current_state != State.DEAD:
		_check_overlapping_damage()


func _process_idle(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_dir != Vector2.ZERO:
		_update_facing(input_dir)
		_change_state(State.WALK)
		return

	if Input.is_action_just_pressed("attack"):
		_change_state(State.ATTACK)
		return

	velocity = Vector2.ZERO
	move_and_slide()
	_animate(delta, _get_frames_for_current_row(), idle_cycle)


func _process_walk(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_dir == Vector2.ZERO:
		_change_state(State.IDLE)
		return

	if Input.is_action_just_pressed("attack"):
		_change_state(State.ATTACK)
		return

	_update_facing(input_dir)
	velocity = input_dir * speed
	move_and_slide()
	_animate(delta, HFRAMES_WALK, walk_cycle)


func _process_attack(delta: float) -> void:
	state_timer += delta
	velocity = Vector2.ZERO
	move_and_slide()

	# Anima o ataque
	_animate(delta, HFRAMES_ATTACK, attack_cycle)

	# Finaliza quando o ciclo de ataque termina
	if state_timer >= attack_cycle:
		sword_collision.disabled = true
		_change_state(State.IDLE)


func _process_hurt(delta: float) -> void:
	state_timer += delta

	# Aplica knockback com desaceleração
	velocity = knockback_velocity
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 0.15)
	move_and_slide()

	_animate(delta, HFRAMES_HURT, hurt_cycle)

	if state_timer >= hurt_duration:
		_change_state(State.IDLE)


func _process_dead(delta: float) -> void:
	state_timer += delta
	velocity = Vector2.ZERO
	move_and_slide()

	_animate(delta, HFRAMES_DEATH, death_cycle)

	# Reinicia cena após animação de morte
	if state_timer >= death_cycle:
		get_tree().reload_current_scene()


## Troca o estado e configura a sprite sheet correspondente.
func _change_state(new_state: State) -> void:
	if current_state == State.DEAD:
		return

	current_state = new_state
	anim_timer = 0.0
	state_timer = 0.0

	_switch_sprite_sheet(new_state)

	# Configurações específicas por estado
	match new_state:
		State.ATTACK:
			_position_sword_hitbox()
			sword_collision.disabled = false
		State.HURT:
			sword_collision.disabled = true
		State.DEAD:
			sword_collision.disabled = true
			sprite.modulate.a = 1.0


## Troca a textura e hframes do sprite conforme o estado.
func _switch_sprite_sheet(state: State) -> void:
	match state:
		State.IDLE:
			sprite.texture = SPRITE_IDLE
			sprite.hframes = HFRAMES_IDLE
		State.WALK:
			sprite.texture = SPRITE_WALK
			sprite.hframes = HFRAMES_WALK
		State.ATTACK:
			sprite.texture = SPRITE_ATTACK
			sprite.hframes = HFRAMES_ATTACK
		State.HURT:
			sprite.texture = SPRITE_HURT
			sprite.hframes = HFRAMES_HURT
		State.DEAD:
			sprite.texture = SPRITE_DEATH
			sprite.hframes = HFRAMES_DEATH

	sprite.vframes = VFRAMES


## Anima o sprite usando duração de ciclo (evita velocidade irregular com frames diferentes).
func _animate(delta: float, frame_count: int, cycle_duration: float) -> void:
	anim_timer += delta
	if anim_timer >= cycle_duration:
		anim_timer -= cycle_duration

	var row: int = facing as int
	var col: int = clampi(
		int((anim_timer / cycle_duration) * frame_count),
		0,
		frame_count - 1
	)
	sprite.frame = row * sprite.hframes + col


## Retorna a quantidade de frames para a linha atual (tratamento especial para Idle UP).
func _get_frames_for_current_row() -> int:
	if current_state == State.IDLE:
		return IDLE_FRAMES_PER_ROW[facing as int]
	return sprite.hframes


## Atualiza a direção com base no vetor de entrada (4 direções).
func _update_facing(input_dir: Vector2) -> void:
	# Prioriza o eixo com maior magnitude
	if absf(input_dir.x) >= absf(input_dir.y):
		if input_dir.x > 0.0:
			facing = Direction.RIGHT
		else:
			facing = Direction.LEFT
	else:
		if input_dir.y > 0.0:
			facing = Direction.DOWN
		else:
			facing = Direction.UP


## Posiciona a hitbox da espada conforme a direção que o jogador está olhando.
func _position_sword_hitbox() -> void:
	match facing:
		Direction.DOWN:
			sword_hitbox.position = Vector2(0, 12)
		Direction.UP:
			sword_hitbox.position = Vector2(0, -12)
		Direction.LEFT:
			sword_hitbox.position = Vector2(-14, 0)
		Direction.RIGHT:
			sword_hitbox.position = Vector2(14, 0)


## Recebe dano de uma fonte externa. Chamado pelo sinal da HurtBox.
func take_damage(amount: int, from_position: Vector2) -> void:
	if damage_cooldown > 0.0 or current_state == State.DEAD:
		return

	hp -= amount
	health_changed.emit(hp, max_hp)
	damage_cooldown = invincibility_duration

	if hp <= 0:
		player_died.emit()
		_change_state(State.DEAD)
		return

	# Knockback — afasta o jogador da fonte de dano
	knockback_velocity = (global_position - from_position).normalized() * knockback_force
	_change_state(State.HURT)


## Callback do sinal area_entered da HurtBox.
func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		take_damage(1, area.global_position)


## Verifica sobreposição contínua para dano por contato (area_entered só dispara uma vez).
func _check_overlapping_damage() -> void:
	for area: Area2D in hurt_box.get_overlapping_areas():
		if area.is_in_group("enemy_hitbox"):
			take_damage(1, area.global_position)
			return


## Efeito de piscar durante invencibilidade — alterna opacidade do sprite.
func _update_blink(delta: float) -> void:
	blink_timer += delta
	if blink_timer >= 0.1:
		blink_timer -= 0.1
		if sprite.modulate.a > 0.5:
			sprite.modulate.a = 0.3
		else:
			sprite.modulate.a = 1.0
