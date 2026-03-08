extends CanvasLayer
## HUD do jogo - exibe coracoes de vida do jogador.
## Conecta-se ao sinal health_changed do Player.

const HEART_FULL = preload("res://assets/sprites/ui/heart_full.png")
const HEART_HALF = preload("res://assets/sprites/ui/heart_half.png")
const HEART_EMPTY = preload("res://assets/sprites/ui/heart_empty.png")

const HEART_SIZE := Vector2(32, 32)
const HEART_MARGIN := 4

@onready var health_container: HBoxContainer = $HealthContainer

var heart_nodes: Array[TextureRect] = []
var max_hp: int = 6


func _ready() -> void:
	# Posiciona o container no canto superior esquerdo
	health_container.position = Vector2(8, 8)
	health_container.add_theme_constant_override("separation", HEART_MARGIN)

	# Espera um frame para o Player ser instanciado
	await get_tree().process_frame
	_find_and_connect_player()


func _find_and_connect_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		max_hp = player.max_hp
		player.health_changed.connect(_on_health_changed)
		_create_hearts()
		_update_hearts(player.hp)


func _create_hearts() -> void:
	# Limpa coracoes anteriores
	for heart in heart_nodes:
		heart.queue_free()
	heart_nodes.clear()

	# Cria um TextureRect por cada 2 pontos de HP (1 coracao = 2 HP)
	@warning_ignore("integer_division")
	var num_hearts := max_hp / 2
	for i in range(num_hearts):
		var heart := TextureRect.new()
		heart.texture = HEART_FULL
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.custom_minimum_size = HEART_SIZE
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		health_container.add_child(heart)
		heart_nodes.append(heart)


func _on_health_changed(new_hp: int) -> void:
	_update_hearts(new_hp)


func _update_hearts(current_hp: int) -> void:
	for i in range(heart_nodes.size()):
		var heart_hp := (i + 1) * 2  # HP que este coracao representa
		if current_hp >= heart_hp:
			heart_nodes[i].texture = HEART_FULL
		elif current_hp >= heart_hp - 1:
			heart_nodes[i].texture = HEART_HALF
		else:
			heart_nodes[i].texture = HEART_EMPTY
