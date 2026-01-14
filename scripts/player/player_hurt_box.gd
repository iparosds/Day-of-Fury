extends Area3D


func _ready() -> void:
	# Identifica que esta área é a "caixa de dano" do player (alvo do inimigo)
	add_to_group("player_hurtbox")


func take_damage(damage: int) -> void:
	var player = get_parent()
	if player.has_method("take_damage"):
		player.take_damage(damage)
