extends Control

func _ready() -> void:
	# Permite que a UI funcione mesmo com o jogo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS


func _on_restart_game_button_pressed() -> void:
	# Remove a pausa do jogo
	get_tree().paused = false
	# Captura o mouse novamente para o gameplay
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Recarrega a cena atual (reinicia o jogo)
	get_tree().reload_current_scene()


func _on_main_menu_button_pressed() -> void:
	# Remove a pausa do jogo
	get_tree().paused = false
	# Libera o mouse para interação com a UI
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Retorna para a cena do menu principal
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
