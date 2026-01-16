extends Node3D

# Referência ao player da cena
@onready var player: CharacterBody3D = $player
# Referência à UI de Game Over
@onready var game_over: Control = $UI/GameOver
# Cena de Game Over
@export var game_over_scene: PackedScene


func _ready() -> void:
	# Garante que a tela de Game Over inicia invisível
	game_over.visible = false
	# Conecta o sinal de morte do player
	player.died.connect(on_player_died)


func on_player_died() -> void:
	# Exibe a tela de Game Over
	game_over.visible = true
	# Pausa o jogo inteiro
	get_tree().paused = true
	# Libera o mouse para interação com a UI
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(_delta: float) -> void:
	# Se o player não existir mais, não atualiza inimigos
	if not is_instance_valid(player):
		return
	# Envia continuamente a posição do player para todos os inimigos
	# do grupo "enemies", permitindo que atualizem seu pathfinding
	get_tree().call_group(
		"enemies",
		"update_target_location",
		player.global_transform.origin
	)
