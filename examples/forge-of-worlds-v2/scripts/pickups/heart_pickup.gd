## Pickup de coração — restaura 1 HP ao jogador ao ser coletado.
extends Area2D

@export var heal_amount: int = 1

@onready var sprite: Sprite2D = $Sprite2D

var _bob_timer: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	# Efeito de flutuar suavemente (bobbing)
	_bob_timer += delta * 3.0
	sprite.position.y = sin(_bob_timer) * 2.0


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.heal(heal_amount)
		# Toca som de coleta antes de remover o pickup
		_play_pickup_sound()
		queue_free()


func _play_pickup_sound() -> void:
	var sfx: AudioStreamPlayer = AudioStreamPlayer.new()
	sfx.stream = preload("res://assets/audio/sfx/handleCoins.ogg")
	sfx.volume_db = -5.0
	# Adiciona ao pai para que o som continue tocando após queue_free()
	get_parent().add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
