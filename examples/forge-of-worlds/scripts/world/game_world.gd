extends Node2D
## Script do mundo principal - The Whispering Glades.
## Instancia o jogador, posiciona slimes e cria paredes de limite.

const PlayerScene := preload("res://scenes/player/player.tscn")
const SlimeScene := preload("res://scenes/enemies/slime.tscn")
const HudScene := preload("res://scenes/ui/hud.tscn")
const NpcScene := preload("res://scenes/npc/npc.tscn")

var player: CharacterBody2D


func _ready() -> void:
	# Configura o fundo verde da clareira
	_setup_background()
	# Cria as paredes de limite do mapa
	_create_walls()
	# Spawna o heroi
	_spawn_player()
	# Spawna os slimes
	_spawn_slimes()
	# Cria o HUD
	add_child(HudScene.instantiate())
	# Spawna o NPC perto da borda da clareira
	_spawn_npc()


func _spawn_npc() -> void:
	var npc := NpcScene.instantiate()
	npc.position = Vector2(-50, -40)
	$NPCs.add_child(npc)


func _setup_background() -> void:
	var bg: ColorRect = $Background
	bg.color = Color(0.15, 0.45, 0.15)
	bg.size = Vector2(800, 600)
	bg.position = Vector2(-400, -300)
	# Garante que o fundo fica atras de tudo
	bg.z_index = -10


func _create_walls() -> void:
	var wall_data := [
		{"pos": Vector2(0, -300), "size": Vector2(800, 16)},   # Topo
		{"pos": Vector2(0, 300), "size": Vector2(800, 16)},    # Baixo
		{"pos": Vector2(-400, 0), "size": Vector2(16, 600)},   # Esquerda
		{"pos": Vector2(400, 0), "size": Vector2(16, 600)},    # Direita
	]

	for wall in wall_data:
		var body := StaticBody2D.new()
		body.position = wall.pos
		body.collision_layer = 1  # layer world
		body.collision_mask = 0

		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = wall.size
		shape.shape = rect
		body.add_child(shape)

		# Visual: borda escura
		var visual := ColorRect.new()
		visual.size = wall.size
		visual.position = -wall.size / 2
		visual.color = Color(0.08, 0.25, 0.08)
		body.add_child(visual)

		add_child(body)


func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	player.position = Vector2(0, 0)
	add_child(player)
	player.died.connect(_on_player_died)


func _spawn_slimes() -> void:
	var positions := [
		Vector2(120, -80),
		Vector2(-100, 90),
		Vector2(180, 100),
	]
	for pos in positions:
		var slime := SlimeScene.instantiate()
		slime.position = pos
		$Enemies.add_child(slime)


func _on_player_died() -> void:
	# Respawna slimes apos morte do jogador
	await get_tree().create_timer(2.5).timeout
	for child in $Enemies.get_children():
		child.queue_free()
	_spawn_slimes()
