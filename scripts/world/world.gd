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

var _death_fade_started := false


func _ready() -> void:
	# Garante que a tela de Game Over inicia invisível
	game_over.visible = false
	# HUD inicia mostrando vidas atuais
	hud.update_lives()
	# Conecta o sinal de morte do player
	player.died.connect(on_player_died)
	player.health_changed.connect(_on_player_health_changed)


func _on_player_health_changed(current: int, _max: int) -> void:
	if current > 0:
		return
	if _death_fade_started:
		return

	# Só faz fade de "Game Over" se esta morte vai zerar as vidas
	if GameManager.player_lives <= 1:
		_death_fade_started = true
		game_over.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		game_over.start_fade(player.death_duration)


func on_player_died() -> void:
	# Player perdeu uma vida
	GameManager.lose_life()
	hud.update_lives()
	if GameManager.has_lives_left():
		# Ainda há vidas -> reinicia a fase automaticamente
		await get_tree().create_timer(1.0).timeout
		get_tree().reload_current_scene()
	else:
		# Acabaram as vidas -> Game Over (imagem já deve ter terminado o fade)
		game_over.finish_and_wait_click()
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		return

	var player_pos := player.global_position
	var aggro_range := 8.0
	var aggro_sq := aggro_range * aggro_range

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue

		# Só atualiza quem estiver perto
		if enemy.global_position.distance_squared_to(player_pos) <= aggro_sq:
			enemy.update_target_location(player_pos)
			enemy.set_aggro(true)
		else:
			# Opcional: força parar se estiver longe (evita "continuar perseguindo")
			enemy.update_target_location(enemy.global_position)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == GameManager.player:
		call_deferred("go_to_next_world")


func go_to_next_world() -> void:
	GameManager.current_level += 1
	GameManager.player_hp = player.health
	if GameManager.current_level >= WORLDS.size():
		get_tree().change_scene_to_file("res://scenes/end.tscn")
		return
	get_tree().change_scene_to_file(WORLDS[GameManager.current_level])
