extends Area3D

func _ready() -> void:
	add_to_group("player_hurtbox")
	monitorable = true  # garante que outros Areas consigam detectar

func take_damage(damage: int) -> void:
	var player := owner
	if is_instance_valid(player) and player.has_method("take_damage"):
		player.take_damage(damage)
