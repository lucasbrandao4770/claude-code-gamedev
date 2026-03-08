## Inimigo Slime — patrulha, perseguição, dano por contato e morte.
extends CharacterBody2D

# Sinais para comunicação com GameManager
signal slime_died

# Direções do sprite (Slime CraftPix: DOWN=0, RIGHT=1, LEFT=2, UP=3)
enum Direction { DOWN, RIGHT, LEFT, UP }

# Estados da máquina de estados
enum State { IDLE, WANDER, CHASE, HURT, DEAD }

# Sprite sheets — cada estado tem colunas/hframes diferentes
const SPRITE_IDLE: Texture2D = preload("res://assets/sprites/enemies/Slime1_Idle_with_shadow.png")
const SPRITE_WALK: Texture2D = preload("res://assets/sprites/enemies/Slime1_Walk_with_shadow.png")
const SPRITE_HURT: Texture2D = preload("res://assets/sprites/enemies/Slime1_Hurt_with_shadow.png")
const SPRITE_DEATH: Texture2D = preload("res://assets/sprites/enemies/Slime1_Death_with_shadow.png")

# Número de colunas (hframes) por estado
const HFRAMES_IDLE: int = 6
const HFRAMES_WALK: int = 8
const HFRAMES_HURT: int = 5
const HFRAMES_DEATH: int = 10

# Número de linhas (vframes) — sempre 4 (DOWN, LEFT, RIGHT, UP)
const VFRAMES: int = 4

# Fonte pixel para números de dano
const PIXEL_FONT: FontFile = preload("res://assets/fonts/PressStart2P-Regular.ttf")

@export_group("Movimento")
@export var wander_speed: float = 30.0
@export var chase_speed: float = 50.0
@export var knockback_force: float = 150.0

@export_group("Combate")
@export var max_hp: int = 3
@export var hurt_duration: float = 0.3
@export var contact_damage: int = 1

@export_group("Animacao")
@export var idle_cycle: float = 1.0
@export var walk_cycle: float = 0.8
@export var hurt_cycle: float = 0.4
@export var death_cycle: float = 1.0

# Referências aos nós filhos
@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_box: Area2D = $HitBox
@onready var hurt_box: Area2D = $HurtBox
@onready var detection_zone: Area2D = $DetectionZone

# Estado interno
var hp: int
var current_state: State = State.IDLE
var facing: Direction = Direction.DOWN
var anim_timer: float = 0.0
var state_timer: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO

# Barra de vida
var hp_bar_bg: ColorRect
var hp_bar_fill: ColorRect

# Referências de perseguição
var player_ref: CharacterBody2D = null
var wander_direction: Vector2 = Vector2.ZERO
var wander_duration: float = 0.0
var idle_duration: float = 0.0


func _ready() -> void:
	hp = max_hp
	_switch_sprite_sheet(State.IDLE)
	# Gera um tempo aleatório para o primeiro IDLE
	idle_duration = randf_range(1.0, 3.0)

	# Conecta sinais da DetectionZone e HurtBox
	detection_zone.body_entered.connect(_on_detection_zone_body_entered)
	detection_zone.body_exited.connect(_on_detection_zone_body_exited)
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)

	# Cria barra de vida
	_create_health_bar()


func _physics_process(delta: float) -> void:
	# Máquina de estados
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.WANDER:
			_process_wander(delta)
		State.CHASE:
			_process_chase(delta)
		State.HURT:
			_process_hurt(delta)
		State.DEAD:
			_process_dead(delta)


## Estado IDLE: fica parado por 1-3 segundos, depois muda para WANDER.
func _process_idle(delta: float) -> void:
	state_timer += delta
	velocity = Vector2.ZERO
	move_and_slide()

	_animate(delta, HFRAMES_IDLE, idle_cycle)

	if state_timer >= idle_duration:
		_start_wander()


## Estado WANDER: caminha em direção aleatória por 1-2 segundos, depois volta para IDLE.
func _process_wander(delta: float) -> void:
	state_timer += delta
	velocity = wander_direction * wander_speed
	_update_facing(velocity)
	move_and_slide()

	_animate(delta, HFRAMES_WALK, walk_cycle)

	if state_timer >= wander_duration:
		_change_state(State.IDLE)
		idle_duration = randf_range(1.0, 3.0)


## Estado CHASE: persegue o jogador enquanto ele estiver na zona de detecção.
func _process_chase(delta: float) -> void:
	if not is_instance_valid(player_ref):
		_change_state(State.IDLE)
		idle_duration = randf_range(1.0, 3.0)
		return

	var direction: Vector2 = (player_ref.global_position - global_position).normalized()
	_update_facing(direction)
	velocity = direction * chase_speed
	move_and_slide()

	_animate(delta, HFRAMES_WALK, walk_cycle)


## Estado HURT: stun breve com knockback, depois retorna ao estado anterior.
func _process_hurt(delta: float) -> void:
	state_timer += delta

	# Aplica knockback com desaceleração
	velocity = knockback_velocity
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 0.15)
	move_and_slide()

	_animate(delta, HFRAMES_HURT, hurt_cycle)

	if state_timer >= hurt_duration:
		# Volta para CHASE se o jogador ainda está na zona, senão IDLE
		if is_instance_valid(player_ref):
			_change_state(State.CHASE)
		else:
			_change_state(State.IDLE)
			idle_duration = randf_range(1.0, 3.0)


## Estado DEAD: toca animação de morte e depois remove o nó.
func _process_dead(delta: float) -> void:
	state_timer += delta
	velocity = Vector2.ZERO
	move_and_slide()

	_animate(delta, HFRAMES_DEATH, death_cycle)

	if state_timer >= death_cycle:
		slime_died.emit()
		queue_free()


## Inicia o estado WANDER com direção e duração aleatórias.
func _start_wander() -> void:
	var angle: float = randf() * TAU
	wander_direction = Vector2(cos(angle), sin(angle))
	wander_duration = randf_range(1.0, 2.0)
	_update_facing(wander_direction)
	_change_state(State.WANDER)


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
		State.HURT:
			sprite.modulate = Color(1, 0.3, 0.3)
		State.DEAD:
			# Desativa colisões ao morrer
			hit_box.set_deferred("monitoring", false)
			hit_box.set_deferred("monitorable", false)
			hurt_box.set_deferred("monitoring", false)
			hurt_box.set_deferred("monitorable", false)
			detection_zone.set_deferred("monitoring", false)
		_:
			sprite.modulate = Color(1, 1, 1)


## Troca a textura e hframes do sprite conforme o estado.
func _switch_sprite_sheet(state: State) -> void:
	match state:
		State.IDLE:
			sprite.texture = SPRITE_IDLE
			sprite.hframes = HFRAMES_IDLE
		State.WANDER, State.CHASE:
			sprite.texture = SPRITE_WALK
			sprite.hframes = HFRAMES_WALK
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


## Atualiza a direção com base no vetor de movimento (4 direções).
func _update_facing(move_dir: Vector2) -> void:
	if move_dir.length() < 0.1:
		return
	if absf(move_dir.x) >= absf(move_dir.y):
		if move_dir.x > 0.0:
			facing = Direction.RIGHT
		else:
			facing = Direction.LEFT
	else:
		if move_dir.y > 0.0:
			facing = Direction.DOWN
		else:
			facing = Direction.UP


## Recebe dano de uma fonte externa. Chamado quando a HurtBox detecta PlayerHitbox.
func take_damage(amount: int, from_position: Vector2) -> void:
	if current_state == State.DEAD or current_state == State.HURT:
		return

	hp -= amount
	_update_health_bar()
	_spawn_damage_number(amount)

	if hp <= 0:
		_change_state(State.DEAD)
		return

	# Knockback — afasta o slime da fonte de dano
	knockback_velocity = (global_position - from_position).normalized() * knockback_force
	_change_state(State.HURT)


## Callback do sinal area_entered da HurtBox — recebe dano da espada do jogador.
func _on_hurt_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hitbox"):
		take_damage(1, area.global_position)


## Cria a barra de vida programaticamente (fundo + preenchimento).
func _create_health_bar() -> void:
	hp_bar_bg = ColorRect.new()
	hp_bar_bg.size = Vector2(20, 3)
	hp_bar_bg.position = Vector2(-10, -18)
	hp_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	hp_bar_bg.visible = false
	add_child(hp_bar_bg)

	hp_bar_fill = ColorRect.new()
	hp_bar_fill.size = Vector2(20, 3)
	hp_bar_fill.position = Vector2(-10, -18)
	hp_bar_fill.color = Color(0.2, 0.8, 0.2, 0.9)
	hp_bar_fill.visible = false
	add_child(hp_bar_fill)


## Atualiza a barra de vida com base no HP atual — muda de cor conforme o percentual.
func _update_health_bar() -> void:
	hp_bar_bg.visible = true
	hp_bar_fill.visible = true
	var ratio: float = float(hp) / float(max_hp)
	hp_bar_fill.size.x = 20.0 * ratio
	if ratio > 0.5:
		hp_bar_fill.color = Color(0.2, 0.8, 0.2, 0.9)
	elif ratio > 0.25:
		hp_bar_fill.color = Color(0.9, 0.7, 0.1, 0.9)
	else:
		hp_bar_fill.color = Color(0.9, 0.2, 0.1, 0.9)


## Exibe número de dano flutuante que sobe e desaparece.
func _spawn_damage_number(amount: int) -> void:
	var label: Label = Label.new()
	label.text = str(amount)
	label.position = Vector2(-4, -26)
	label.add_theme_font_override("font", PIXEL_FONT)
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	add_child(label)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 20, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)


## Callback do sinal body_entered da DetectionZone — jogador entrou no raio de perseguição.
func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = body as CharacterBody2D
		if current_state != State.HURT and current_state != State.DEAD:
			_change_state(State.CHASE)


## Callback do sinal body_exited da DetectionZone — jogador saiu do raio de perseguição.
func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_ref = null
		if current_state == State.CHASE:
			_change_state(State.IDLE)
			idle_duration = randf_range(1.0, 3.0)
