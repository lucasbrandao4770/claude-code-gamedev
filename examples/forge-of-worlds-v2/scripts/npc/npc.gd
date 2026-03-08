## NPC com sistema de diálogo — pausa o jogo durante conversa.
extends Area2D

@export var npc_name: String = "Villager"
@export var dialog_lines: PackedStringArray = [
	"Welcome to the Whispering Glades, traveler!",
	"Watch out for the Slimes... they look harmless, but they bite!",
	"May your sword stay sharp and your heart stay brave."
]

@onready var prompt_label: Label = $PromptLabel
@onready var dialog_panel: CanvasLayer = $DialogPanel
@onready var dialog_label: Label = $DialogPanel/PanelContainer/MarginContainer/VBox/DialogLabel
@onready var continue_label: Label = $DialogPanel/PanelContainer/MarginContainer/VBox/ContinueLabel

var player_in_range: bool = false
var dialog_active: bool = false
var current_line: int = 0


# Precisa processar mesmo com o jogo pausado
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	dialog_panel.visible = false
	prompt_label.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if dialog_active:
			_advance_dialog()
			get_viewport().set_input_as_handled()
		elif player_in_range:
			_start_dialog()
			get_viewport().set_input_as_handled()


func _start_dialog() -> void:
	dialog_active = true
	GameManager.dialog_active = true
	current_line = 0
	prompt_label.visible = false
	dialog_panel.visible = true
	dialog_label.text = npc_name + ": " + dialog_lines[current_line]
	_update_continue_hint()
	get_tree().paused = true


func _advance_dialog() -> void:
	current_line += 1
	if current_line >= dialog_lines.size():
		_end_dialog()
		return
	dialog_label.text = npc_name + ": " + dialog_lines[current_line]
	_update_continue_hint()


## Mostra ou esconde o indicador de continuação.
func _update_continue_hint() -> void:
	continue_label.visible = current_line < dialog_lines.size() - 1


func _end_dialog() -> void:
	dialog_active = false
	GameManager.dialog_active = false
	dialog_panel.visible = false
	get_tree().paused = false
	if player_in_range:
		prompt_label.visible = true


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		if not dialog_active:
			prompt_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		prompt_label.visible = false
