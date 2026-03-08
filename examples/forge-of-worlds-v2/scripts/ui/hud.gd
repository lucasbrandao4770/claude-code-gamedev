## HUD — exibe os corações de vida do jogador.
extends CanvasLayer

const HEART_FULL: Texture2D = preload("res://assets/sprites/ui/heart_full.png")
const HEART_EMPTY: Texture2D = preload("res://assets/sprites/ui/heart_empty.png")

@onready var health_container: HBoxContainer = $MarginContainer/HealthContainer


func _ready() -> void:
	GameManager.player_hp_changed.connect(_update_hearts)
	_update_hearts(GameManager.player_hp, GameManager.player_max_hp)


## Atualiza os corações do HUD conforme o HP atual e máximo.
func _update_hearts(current_hp: int, max_hp: int) -> void:
	# Remove corações anteriores
	for child: Node in health_container.get_children():
		child.queue_free()

	# Cada coração representa 1 ponto de HP
	for i: int in range(max_hp):
		var heart: TextureRect = TextureRect.new()
		heart.custom_minimum_size = Vector2(16, 16)
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

		if i < current_hp:
			heart.texture = HEART_FULL
		else:
			heart.texture = HEART_EMPTY

		health_container.add_child(heart)
