extends Node
# Armazena uma referência global ao player
# para acesso por outros scripts do jogo.

# Referência ao nó do player
var player: Node
var player_lives : int = 3
const MAX_LIVES : int = 3

func set_player(player_node: Node) -> void:
	# Define o player atual do jogo
	player = player_node


func reset_lives() -> void:
	player_lives = MAX_LIVES


func lose_life() -> void:
	player_lives -= 1


func has_lives_left() -> bool:
	return player_lives > 0
