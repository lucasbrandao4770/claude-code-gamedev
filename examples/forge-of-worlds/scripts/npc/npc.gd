extends Area2D
## NPC interagivel - guarda veterano das Whispering Glades.
## Dialogo classico RPG: caixa na parte inferior da tela, pausa o jogo.

const IDLE_SHEET = preload("res://assets/sprites/npcs/Knight/Idle/Idle-Sheet.png")
const PIXEL_FONT = preload("res://assets/fonts/PressStart2P-Regular.ttf")

var dialog_lines: Array[String] = [
	"These stones hum with forgotten magic...\nThe slimes are drawn to it.\nStrike true, traveler.",
	"This world was forged by a Worldsmith\nand a curious soul, speaking\nthrough a bridge of code.",
	"Press SPACE to swing your sword.\nThe slimes are docile...\nuntil you get too close.",
]

var current_line: int = -1
var is_player_nearby: bool = false
var is_dialog_active: bool = false
var anim_frame: int = 0
var anim_timer: float = 0.0

# UI do dialogo (criada dinamicamente)
var dialog_layer: CanvasLayer = null
var dialog_panel: PanelContainer = null
var dialog_label: Label = null
var advance_label: Label = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_label: Label = $PromptLabel


func _ready() -> void:
	sprite.texture = IDLE_SHEET
	sprite.hframes = 4
	sprite.vframes = 1
	sprite.frame = 0

	add_to_group("npc")
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Colisao para detectar proximidade do jogador
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false

	# Configura prompt "[E]" acima do NPC
	_setup_prompt()

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _setup_prompt() -> void:
	prompt_label.position = Vector2(-12, -24)
	prompt_label.size = Vector2(24, 12)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if PIXEL_FONT:
		prompt_label.add_theme_font_override("font", PIXEL_FONT)
	prompt_label.add_theme_font_size_override("font_size", 8)
	prompt_label.add_theme_color_override("font_color", Color.YELLOW)
	prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt_label.add_theme_constant_override("outline_size", 2)
	prompt_label.text = "[E]"
	prompt_label.visible = false


func _process(delta: float) -> void:
	anim_timer += delta
	if anim_timer >= 0.3:
		anim_timer = 0.0
		anim_frame = (anim_frame + 1) % 4
		sprite.frame = anim_frame


func interact() -> void:
	if not is_dialog_active:
		is_dialog_active = true
		current_line = 0
		prompt_label.visible = false
		_create_dialog_ui()
		_show_line()
		get_tree().paused = true
	else:
		current_line += 1
		if current_line >= dialog_lines.size():
			_end_dialog()
		else:
			_show_line()


func _create_dialog_ui() -> void:
	# CanvasLayer para UI fixa na tela
	dialog_layer = CanvasLayer.new()
	dialog_layer.layer = 10
	dialog_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(dialog_layer)

	# Painel semi-transparente na parte inferior
	dialog_panel = PanelContainer.new()
	dialog_panel.anchor_left = 0.05
	dialog_panel.anchor_right = 0.95
	dialog_panel.anchor_top = 0.7
	dialog_panel.anchor_bottom = 0.95
	dialog_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	# Estilo do painel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.15, 0.9)
	style.border_color = Color(0.6, 0.5, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	dialog_panel.add_theme_stylebox_override("panel", style)
	dialog_layer.add_child(dialog_panel)

	# Container vertical para texto + indicador
	var vbox := VBoxContainer.new()
	vbox.process_mode = Node.PROCESS_MODE_ALWAYS
	dialog_panel.add_child(vbox)

	# Label do texto
	dialog_label = Label.new()
	dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialog_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if PIXEL_FONT:
		dialog_label.add_theme_font_override("font", PIXEL_FONT)
	dialog_label.add_theme_font_size_override("font_size", 10)
	dialog_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(dialog_label)

	# Indicador para avancar
	advance_label = Label.new()
	advance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if PIXEL_FONT:
		advance_label.add_theme_font_override("font", PIXEL_FONT)
	advance_label.add_theme_font_size_override("font_size", 8)
	advance_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.3))
	vbox.add_child(advance_label)


func _show_line() -> void:
	if dialog_label == null:
		return
	dialog_label.text = dialog_lines[current_line]
	if current_line < dialog_lines.size() - 1:
		advance_label.text = "[E] next >"
	else:
		advance_label.text = "[E] close"


func _end_dialog() -> void:
	is_dialog_active = false
	current_line = -1
	get_tree().paused = false

	if dialog_layer:
		dialog_layer.queue_free()
		dialog_layer = null
		dialog_label = null
		advance_label = null

	if is_player_nearby:
		prompt_label.visible = true


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = true
		if not is_dialog_active:
			prompt_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = false
		prompt_label.visible = false
		if is_dialog_active:
			_end_dialog()
