extends CharacterBody3D

# Velocidade base de movimentação do spider
const SPEED : float = 3.0

@onready var spider_hit_box: Area3D = $SpiderHitBox
# Controla as animações do inimigo
@onready var animation_player: AnimationPlayer = $SpiderPC1/AnimationPlayer
# Agente de navegação responsável por pathfinding e avoidance
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
# Vida máxima configurável pelo editor
@export var max_health: int = 50

signal health_changed(current: int, max: int)

# Vida atual do inimigo
var health: int
# Indica se o player está dentro da área de ataque
var player_in_range: bool = false
# Indica se o inimigo já morreu (trava toda a lógica)
var is_dead: bool = false
# Indica se o inimigo está em animação de dano
var is_hurt: bool = false


func _ready() -> void:
	# Inicializa a vida do inimigo
	health = max_health
	emit_signal("health_changed", health, max_health)
	# Adiciona o spider ao grupo de inimigos
	add_to_group("enemies")
	# Ativa o sistema de avoidance para evitar empilhamento entre spiders
	navigation_agent.avoidance_enabled = true
	# Raio físico considerado para desvio
	navigation_agent.radius = 0.8
	# Distância mínima mantida entre spiders
	navigation_agent.neighbor_distance = 2.0
	# Quantidade máxima de vizinhos considerados no avoidance
	navigation_agent.max_neighbors = 6


func _physics_process(_delta: float) -> void:
	# Se estiver morto, para completamente
	if is_dead:
		navigation_agent.set_velocity(Vector3.ZERO)
		return
	# Se estiver tomando dano, interrompe movimento e ataque
	if is_hurt:
		navigation_agent.set_velocity(Vector3.ZERO)
		return
	# Se o player estiver ao alcance, entra em modo de ataque
	if player_in_range:
		if GameManager.player:
			# Mantém o spider olhando para o player
			look_at(GameManager.player.global_position, Vector3.UP)
			rotate_y(PI)
		navigation_agent.set_velocity(Vector3.ZERO)
		# Ataca em loop enquanto o player estiver na área
		if animation_player.current_animation != "attack" or not animation_player.is_playing():
			animation_player.play("attack")
		return
	# Calcula o próximo ponto do caminho até o player
	var current_location = global_transform.origin
	var next_location = navigation_agent.get_next_path_position()
	# Direção de movimento no plano (XZ)
	var dir = next_location - current_location
	# Evita movimento vertical (subir em outros spiders)
	dir.y = 0.0
	var new_velocity = dir.normalized() * SPEED
	# Se houver deslocamento, persegue o player
	if new_velocity.length() > 0.01:
		animation_player.play("walk")
		if GameManager.player:
			look_at(GameManager.player.global_position, Vector3.UP)
			rotate_y(PI)
	else:
		# Caso contrário, permanece parado
		animation_player.play("idle")
	# Envia a velocidade para o NavigationAgent
	navigation_agent.set_velocity(new_velocity)


func take_damage(damage: int) -> void:
	# Ignora dano se já estiver morto
	if is_dead:
		return
	# Aplica dano
	health -= damage
	health = clamp(health, 0, max_health)
	emit_signal("health_changed", health, max_health)
	# Se a vida chegar a zero, inicia morte
	if health <= 0:
		die()
		return
	# Entra em estado de dano temporário
	is_hurt = true
	navigation_agent.set_velocity(Vector3.ZERO)
	animation_player.play("dano")
	await get_tree().create_timer(0.4).timeout
	is_hurt = false


func die() -> void:
	# Evita executar morte mais de uma vez
	if is_dead:
		return
	is_dead = true
	player_in_range = false
	navigation_agent.set_velocity(Vector3.ZERO)
	# Toca animação de morte e aguarda antes de remover o nó
	animation_player.play("killed")
	await get_tree().create_timer(1.9).timeout
	queue_free()


func update_target_location(target_location):
	# Atualiza a posição alvo do NavigationAgent
	navigation_agent.target_position = target_location


func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	# Aplica a velocidade final calculada pelo avoidance
	velocity = velocity.move_toward(safe_velocity, 0.25)
	move_and_slide()


func _on_hurt_box_area_entered(area: Area3D) -> void:
	# Detecta entrada do hitbox do player na área de ataque
	if not area.is_in_group("player_hitbox"):
		return
	player_in_range = true


func _on_hurt_box_area_exited(area: Area3D) -> void:
	# Detecta saída do player da área de ataque
	if not area.is_in_group("player_hitbox"):
		return
	player_in_range = false


# Ativa o hitbox de ataque do spider.
# Essa função é chamada via AnimationPlayer (track de chamada de método)
func attack_hitbox_enable() -> void:
	spider_hit_box.enable()


# Desativa o hitbox de ataque do spider.
# Também é chamada pela animação para garantir que o dano
# só seja aplicado durante os frames corretos do ataque.
func attack_hitbox_disable() -> void:
	spider_hit_box.disable()
