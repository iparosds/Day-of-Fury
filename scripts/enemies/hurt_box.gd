extends Area3D

# Recebe dano pela área e repassa para o nó pai (entidade dona da área)
func take_damage(damage: int) -> void:
	# Considera o pai como o inimigo
	var enemy = get_parent()
	# Encaminha o dano apenas se o pai suportar o método
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
