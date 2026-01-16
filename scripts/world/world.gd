extends Node3D

# Referência ao player da cena
@onready var player: CharacterBody3D = $player
# Referência à UI de Game Over
@onready var game_over: Control = $UI/GameOver
# Cena de Game Over
@export var game_over_scene: PackedScene
@onready var hud: Control = $UI/HUD


func _ready() -> void:
	# Garante que a tela de Game Over inicia invisível
	game_over.visible = false
	# HUD inicia mostrando vidas atuais
	hud.update_lives()
	# Conecta o sinal de morte do player
	player.died.connect(on_player_died)


func on_player_died() -> void:
	# Player perdeu uma vida
	GameManager.lose_life()
	hud.update_lives()
	if GameManager.has_lives_left():
		# Ainda há vidas -> reinicia a fase automaticamente
		await get_tree().create_timer(1.0).timeout
		get_tree().reload_current_scene()
	else:
		# Acabaram as vidas -> Game Over
		game_over.visible = true
		get_tree().paused = true
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
