extends Node3D

# Referência ao player da cena
@onready var player: CharacterBody3D = $player
# Referência à UI de Game Over
@onready var game_over: Control = $UI/GameOver
# Cena de Game Over
@export var game_over_scene: PackedScene
@onready var hud: Control = $UI/HUD

# Ordem das fases
const WORLDS := [
	"res://scenes/world.tscn",
	"res://scenes/world2.tscn",
	"res://scenes/world3.tscn"
]



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


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == GameManager.player:
		call_deferred("go_to_next_world")


func go_to_next_world() -> void:
	GameManager.current_level += 1
	# Se não houver mais fases, você decide o que fazer
	if GameManager.current_level >= WORLDS.size():
		# Exemplo simples: volta pro menu
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	get_tree().change_scene_to_file(WORLDS[GameManager.current_level])
