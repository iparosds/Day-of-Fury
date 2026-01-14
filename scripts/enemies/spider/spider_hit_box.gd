extends Area3D

# Dano causado pelo ataque do spider
var damage := 3

# Guarda as hurtboxes já atingidas neste ataque
# (evita aplicar dano múltiplas vezes no mesmo alvo)
var hit_targets := {}


func _ready() -> void:
	# Identifica esta área como hitbox de inimigo
	add_to_group("spider_hitbox")
	# Começa desativada; só causa dano quando o ataque estiver ativo
	monitoring = false
	# Detecta quando uma hurtbox entra na área durante o ataque
	area_entered.connect(_on_area_entered)


func enable() -> void:
	# Reinicia a lista de alvos atingidos para um novo ataque
	hit_targets.clear()
	# Ativa a detecção de colisões
	monitoring = true
	# Aplica dano imediato em áreas que já estejam sobrepondo
	for area in get_overlapping_areas():
		_try_hit(area)


func disable() -> void:
	# Desativa a detecção de colisões ao fim do ataque
	monitoring = false


func _on_area_entered(area: Area3D) -> void:
	# Tenta causar dano quando uma área entra na hitbox
	_try_hit(area)


func _try_hit(area: Area3D) -> void:
	# Aplica dano apenas na hurtbox do player
	if not area.is_in_group("player_hurtbox"):
		return
	# Evita causar dano repetido no mesmo alvo no mesmo ataque
	if hit_targets.has(area):
		return
	# Marca o alvo como atingido
	hit_targets[area] = true
	# Encaminha o dano para a entidade dona da hurtbox
	if area.has_method("take_damage"):
		area.take_damage(damage)
