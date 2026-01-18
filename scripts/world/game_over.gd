extends Control

@onready var image: TextureRect = $TextureRect
@onready var ui: Control = $Control  # onde ficam seus botões/labels

var _can_click_to_menu := false
var _tween: Tween

func _ready() -> void:
	# Permite UI funcionar mesmo com o jogo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Segurança: imagem não pode "roubar" clique dos botões
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Começa com imagem e UI invisíveis (alpha 0)
	image.modulate = Color(1, 1, 1, 0)
	ui.modulate = Color(1, 1, 1, 0)

	_can_click_to_menu = false

func start_fade(duration: float) -> void:
	visible = true
	_can_click_to_menu = false

	if _tween:
		_tween.kill()

	image.modulate = Color(1, 1, 1, 0)
	ui.modulate = Color(1, 1, 1, 0)

	_tween = create_tween()
	_tween.tween_property(image, "modulate", Color(1, 1, 1, 1), max(duration, 0.01))

func finish_and_wait_click() -> void:
	visible = true

	if _tween:
		_tween.kill()

	# No fim da morte: imagem 100% + botões aparecem
	image.modulate = Color(1, 1, 1, 1)

	var t := create_tween()
	t.tween_property(ui, "modulate", Color(1, 1, 1, 1), 0.2)

	_can_click_to_menu = true

func _unhandled_input(event: InputEvent) -> void:
	# Só volta pro menu com clique/attack se o clique NÃO for consumido pelos botões.
	if not visible or not _can_click_to_menu:
		return

	if event.is_action_pressed("attack"):
		_on_main_menu_button_pressed()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_main_menu_button_pressed()

# IMPORTANT: manter estes nomes, porque seus botões já estão conectados neles.
func _on_restart_game_button_pressed() -> void:
	GameManager.reset_lives()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Escolha UMA das opções abaixo:

	# (A) Reinicia direto no jogo (primeira fase)
	get_tree().change_scene_to_file("res://scenes/world.tscn")

	# (B) Se você quiser mostrar a HQ de novo ao reiniciar, use esta e comente a de cima:
	# get_tree().change_scene_to_file("res://scenes/intro_comic.tscn")

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
