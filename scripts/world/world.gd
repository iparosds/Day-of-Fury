extends Node3D

# Referência ao player usada como alvo global dos inimigos
@onready var player: CharacterBody3D = $player


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	# A cada frame de física, envia a posição atual do player
	# para todos os nós do grupo "enemies", permitindo que cada
	# inimigo atualize seu NavigationAgent e persiga o jogador
	get_tree().call_group(
		"enemies",
		"update_target_location",
		player.global_transform.origin
	)
