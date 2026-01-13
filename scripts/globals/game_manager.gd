extends Node
# Armazena uma referência global ao player
# para acesso por outros scripts do jogo.

# Referência ao nó do player
var player: Node


func set_player(player_node: Node) -> void:
	# Define o player atual do jogo
	player = player_node
