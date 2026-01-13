extends Area3D

# Dano aplicado a cada alvo atingido
@export var damage := 10

# Registra alvos já atingidos para evitar dano duplicado no mesmo ataque
var hit_targets := {}


func _ready() -> void:
	# Área inicia desativada
	monitoring = false
	# Detecta entrada de novas áreas durante o ataque
	area_entered.connect(_on_area_entered)


func enable() -> void:
	# Reinicia a lista de alvos atingidos
	hit_targets.clear()
	# Ativa a detecção de colisão
	monitoring = true
	# Aplica dano em áreas que já estavam sobrepondo ao ativar
	for area in get_overlapping_areas():
		_try_hit(area)


func disable() -> void:
	# Desativa a detecção de colisão
	monitoring = false


func _on_area_entered(area: Area3D) -> void:
	# Tenta aplicar dano ao alvo que entrou na área
	_try_hit(area)


func _try_hit(area: Area3D) -> void:
	# Ignora se o alvo já foi atingido neste ataque
	if hit_targets.has(area):
		return
	# Marca o alvo como atingido
	hit_targets[area] = true
	# Aplica dano apenas se o alvo suportar o método
	if area.has_method("take_damage"):
		area.take_damage(damage)
