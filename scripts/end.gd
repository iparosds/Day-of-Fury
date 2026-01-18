extends Control

@onready var page: TextureRect = $TextureRect
const PAGE := "res://assets/images/hq_5.png"

func _ready() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	page.texture = load(PAGE) as Texture2D

func _input(event: InputEvent) -> void:
	if _is_advance_event(event):
		# Volta pro menu (o Play já reseta as vidas)
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _is_advance_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return true
	if event.is_action_pressed("attack"):
		return true
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]
	return false
