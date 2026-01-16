extends Control

# Nó que recebe o efeito de parallax (movimento suave)
@onready var control_2: Control = $Control2
# Containers de UI
@onready var main_menu_container: VBoxContainer = $Control/MainMenuContainer
@onready var credits_container: VBoxContainer = $Control/CreditsContainer
# Labels de título
@onready var game_label: Label = $Control/GameLabel
@onready var credits_label: Label = $Control/CreditsLabel

# Centro da tela, usado como referência para o parallax
var center: Vector2


func _ready() -> void:
	# Garante que o jogo não esteja pausado ao entrar no menu
	get_tree().paused = false
	# Mouse visível para interação com a UI
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Calcula o centro da tela
	center = get_viewport_rect().size * 0.5
	# Estado inicial: menu principal visível, créditos ocultos
	main_menu_container.visible = true
	game_label.visible = true
	credits_container.visible = false
	credits_label.visible = false


func _process(delta: float) -> void:
	# Efeito de parallax:
	# move o Control2 suavemente em direção ao offset calculado pelo mouse
	var offset = center - get_global_mouse_position() * 0.1
	control_2.position = control_2.position.lerp(offset, 8.0 * delta)


func _on_play_button_pressed() -> void:
	GameManager.reset_lives()
	# Inicia o jogo carregando a cena principal
	get_tree().change_scene_to_file("res://scenes/world.tscn")


func _on_credits_button_pressed() -> void:
	# Alterna para a tela de créditos
	main_menu_container.visible = false
	game_label.visible = false
	credits_container.visible = true
	credits_label.visible = true


func _on_main_menu_button_pressed() -> void:
	# Retorna da tela de créditos para o menu principal
	credits_container.visible = false
	credits_label.visible = false
	main_menu_container.visible = true
	game_label.visible = true


func _on_quit_button_pressed() -> void:
	# Encerra o jogo
	get_tree().paused = false
	get_tree().quit()


func _on_item_rect_changed() -> void:
	# Recalcula o centro da tela ao redimensionar a janela
	center = get_viewport_rect().size * 0.5
	# Reposiciona o Control2 no novo centro
	if control_2 != null:
		control_2.global_position = center
