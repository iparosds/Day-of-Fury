extends Control

@onready var page: TextureRect = $TextureRect

const PAGES := [
	"res://assets/images/hq_1.png",
	"res://assets/images/hq_2.png",
	"res://assets/images/hq_3.png",
	"res://assets/images/hq_4.png",
]

var idx: int = 0

func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_page()

func _input(event: InputEvent) -> void:
	if _is_advance_event(event):
		_advance()

func _is_advance_event(event: InputEvent) -> bool:
	# Clique normal
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return true

	if event.is_action_pressed("attack"):
		return true

	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]

	return false

func _show_page() -> void:
	page.texture = load(PAGES[idx]) as Texture2D

func _advance() -> void:
	idx += 1
	if idx >= PAGES.size():
		# Segurança: garante que o jogo começa do world 1
		GameManager.current_level = 0
		get_tree().change_scene_to_file("res://scenes/world.tscn")
		return

	_show_page()
