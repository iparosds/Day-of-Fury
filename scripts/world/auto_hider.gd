extends CSGBox3D
# Controla se o objeto fica no foreground ou background
# com base na posição horizontal (eixo X) do player.

# Estado interno para evitar reconfigurar layers a cada frame
var layer = 0


func _process(_delta: float) -> void:
	if not is_instance_valid(GameManager.player):
		return
	# Se o player estiver à direita do objeto,
	# o objeto vai para o background.
	# Caso contrário, fica no foreground.
	if GameManager.player.global_position.x > global_position.x:
		set_to_background()
	else:
		set_to_foreground()


func set_to_foreground() -> void:
	# Ativa a layer de foreground apenas se ainda não estiver ativa
	if layer != 2:
		layer = 2
		set_layer_mask_value(1, false)
		set_layer_mask_value(2, true)


func set_to_background() -> void:
	# Ativa a layer de background apenas se ainda não estiver ativa
	if layer != 1:
		layer = 1
		set_layer_mask_value(1, true)
		set_layer_mask_value(2, false)
