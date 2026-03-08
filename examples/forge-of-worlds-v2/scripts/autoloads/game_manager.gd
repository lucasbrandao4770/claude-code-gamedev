extends Node
## Gerenciador global do estado do jogo

signal player_hp_changed(current_hp: int, max_hp: int)
signal player_died

var player_hp: int = 6
var player_max_hp: int = 6

func reset() -> void:
	player_hp = player_max_hp
	player_hp_changed.emit(player_hp, player_max_hp)

func take_damage(amount: int) -> void:
	player_hp = maxi(player_hp - amount, 0)
	player_hp_changed.emit(player_hp, player_max_hp)
	if player_hp <= 0:
		player_died.emit()

func heal(amount: int) -> void:
	player_hp = mini(player_hp + amount, player_max_hp)
	player_hp_changed.emit(player_hp, player_max_hp)
