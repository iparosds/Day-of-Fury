extends CharacterBody3D

# Velocidade máxima de movimento no chão
const SPEED: float = 4.0
# Impulso vertical aplicado ao pular
const JUMP_VELOCITY: float = 4.5
# Aceleração ao iniciar/mudar direção
const ACCELERATION: float = 18.0
# Desaceleração ao soltar o movimento
const DECELERATION: float = 22.0

# Estados básicos do player para controlar animações e regras de movimento
enum PlayerState { IDLE, RUN, JUMP, ATTACK, HURT, DEATH }

@onready var animation_player: AnimationPlayer = $visuals/dev_hero/AnimationPlayer
#@onready var animation_player: AnimationPlayer = $visuals/robot/AnimationPlayer
@onready var visuals: Node3D = $visuals
# Ponto usado pela câmera externa para seguir o player.
@onready var camera_point: Node3D = $camera_point 
# Vida máxima configurável no inspector
@export var max_health: int = 100
@export var death_duration: float = 2.5


signal health_changed(current: int, max: int)
signal died

# Vida atual do player
var health: int
# Estado atual do player
var state: int = PlayerState.IDLE
# Direção de movimento calculada a partir do input
var move_dir: Vector3 = Vector3.ZERO
# Cache do estado de chão do frame anterior (para detectar transições)
var was_on_floor: bool = false


func _ready() -> void:
	if GameManager.player_hp >= 0:
		health = GameManager.player_hp
	else:
		health = 100
	# Registra o player no GameManager
	GameManager.set_player(self)
	emit_signal("health_changed", health, max_health)
	# Suaviza transições entre animações
	animation_player.set_blend_time("Idle", "Run", 0.2)
	animation_player.set_blend_time("Run", "Idle", 0.2)
	animation_player.set_blend_time("Idle", "Jump", 0.2)
	animation_player.set_blend_time("Jump", "Idle", 0.2)
	# Detecta quando animações terminam
	animation_player.animation_finished.connect(_on_animation_finished)
	# Inicializa estado de chão e animação
	was_on_floor = is_on_floor()
	_set_state(PlayerState.IDLE)


func _physics_process(delta: float) -> void:
	# Guarda se estava no chão no começo do frame
	var prev_on_floor := was_on_floor
	# Lê input e converte para direção no mundo usando a base do player
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	move_dir = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	# Aplica gravidade apenas quando estiver no ar
	if not prev_on_floor:
		velocity += get_gravity() * delta
	if state == PlayerState.DEATH:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		was_on_floor = is_on_floor()
		return
	# Estado HURT: permite que a animação de dano seja interrompida por ataque, pulo ou movimento,
	# evitando que o player fique totalmente incapacitado.
	if state == PlayerState.HURT:
		# Cancela se o jogador tentar fazer algo
		if Input.is_action_just_pressed("attack"):
			_set_state(PlayerState.ATTACK)
		elif Input.is_action_just_pressed("ui_accept") and prev_on_floor:
			velocity.y = JUMP_VELOCITY
			_set_state(PlayerState.JUMP)
		elif move_dir != Vector3.ZERO:
			_set_state(PlayerState.RUN)
		else:
			# sem input: mantém hurt e segura o deslize
			velocity.x = move_toward(velocity.x, 0.0, DECELERATION * 3.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, DECELERATION * 3.0 * delta)
		# Executa apenas a física básica neste frame e encerra o processamento,
		# impedindo que a lógica normal de movimento/ataque rode junto com o HURT.
		move_and_slide()
		was_on_floor = is_on_floor()
		return	
	# Inicia ataque (uma vez por clique)
	if Input.is_action_just_pressed("attack") and state != PlayerState.ATTACK:
		_set_state(PlayerState.ATTACK)
	# Pula apenas se estava no chão no início do frame
	if Input.is_action_just_pressed("ui_accept") and prev_on_floor:
		velocity.y = JUMP_VELOCITY
		_set_state(PlayerState.JUMP)
	# Atualiza velocidade horizontal conforme estado e input
	apply_movement(delta, prev_on_floor)
	# Rotaciona o visual para a direção do movimento
	apply_rotation()
	# Move o corpo com colisão
	move_and_slide()
	# Atualiza estado de chão após mover
	var now_on_floor := is_on_floor()
	was_on_floor = now_on_floor
	# Trata transições chão/ar
	handle_floor_transitions(prev_on_floor, now_on_floor)
	# Fallback de segurança: se a animação de ataque foi interrompida por outro estado,
	# corrige automaticamente para Idle ou Run conforme o input e o chão.
	if state == PlayerState.ATTACK and animation_player.current_animation != "Attack1":
		apply_ground_state_by_input(now_on_floor)


# Necessária para detectar "acabou de cair" e "acabou de pousar" e ajustar o estado,
# sem depender de checagens espalhadas pelo código.
func handle_floor_transitions(prev_on_floor: bool, now_on_floor: bool) -> void:
	# Saiu do chão: entra em JUMP (exceto se estiver atacando)
	if prev_on_floor and not now_on_floor:
		if state != PlayerState.ATTACK:
			_set_state(PlayerState.JUMP)
		return
	# Tocou no chão: decide Idle/Run se estava em JUMP ou ATTACK
	if not prev_on_floor and now_on_floor:
		if state == PlayerState.JUMP or state == PlayerState.ATTACK:
			apply_ground_state_by_input(true)


# Necessária para centralizar o cálculo de velocidade X/Z (aceleração, desaceleração)
# e também decidir RUN/IDLE quando estiver no chão.
func apply_movement(delta: float, prev_on_floor: bool) -> void:
	# Durante ATTACK: mantém momentum e desacelera suavemente
	if state == PlayerState.ATTACK:
		var attack_deceleration := (DECELERATION * 0.15) * delta
		velocity.x = move_toward(velocity.x, 0.0, attack_deceleration)
		velocity.z = move_toward(velocity.z, 0.0, attack_deceleration)
		return
	# Alvo de velocidade no plano XZ
	var target_x := move_dir.x * SPEED
	var target_z := move_dir.z * SPEED
	if move_dir != Vector3.ZERO:
		# Acelera em direção ao alvo
		velocity.x = move_toward(velocity.x, target_x, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, target_z, ACCELERATION * delta)
		# No chão e fora do JUMP: RUN
		if state != PlayerState.JUMP and prev_on_floor:
			_set_state(PlayerState.RUN)
	else:
		# Sem input: desacelera até parar
		velocity.x = move_toward(velocity.x, 0.0, DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0.0, DECELERATION * delta)
		# No chão e fora do JUMP: IDLE
		if state != PlayerState.JUMP and prev_on_floor:
			_set_state(PlayerState.IDLE)


# Necessária para manter o visual virado para a direção do movimento,
# separando rotação da lógica de movimento.
func apply_rotation() -> void:
	# Não rotaciona sem direção
	if move_dir == Vector3.ZERO:
		return
	# Olha para um ponto à frente para estabilizar a rotação
	visuals.look_at(global_position + (move_dir * 2.0), Vector3.UP)


# Necessária para "fechar o ciclo" do ataque: quando Attack1 termina,
# devolve o estado correto (Idle/Run) conforme chão e input.
func _on_animation_finished(anim_name: StringName) -> void:
	# Ao finalizar o ataque, volta para Idle/Run conforme a situação
	if anim_name == "Attack1":
		apply_ground_state_by_input(is_on_floor())


# Necessária para decidir o estado padrão quando não há uma ação "forçando" estado:
# no ar mantém JUMP; no chão escolhe RUN ou IDLE baseado no input atual.
func apply_ground_state_by_input(on_floor: bool) -> void:
	# No ar: mantém JUMP (exceto se estiver atacando)
	if not on_floor:
		if state != PlayerState.ATTACK:
			_set_state(PlayerState.JUMP)
		return
	# No chão: decide RUN/IDLE pelo input atual
	if move_dir != Vector3.ZERO:
		_set_state(PlayerState.RUN)
	else:
		_set_state(PlayerState.IDLE)


# Necessária para centralizar a troca de estado + animação e evitar replays repetidos,
# garantindo que cada estado toque a animação correspondente uma única vez.
func _set_state(new_state: int) -> void:
	# Evita re-tocar animação se o estado não mudou
	if state == new_state:
		return
	state = new_state
	# Toca a animação correspondente ao estado
	match state:
		PlayerState.ATTACK:
			animation_player.play("Attack1")
		PlayerState.JUMP:
			animation_player.play("Jump")
		PlayerState.RUN:
			animation_player.play("Run")
		PlayerState.HURT:
			animation_player.play("Hurt")
		PlayerState.DEATH:
			animation_player.play("Hurt")
		_:
			animation_player.play("Idle")


# Aplica dano ao player acionando o estado HURT:
# a animação de dano pode ser interrompida por ataque, movimento ou pulo,
# evitando travar o controle do personagem.
func take_damage(damage: int) -> void:
	# Se já morreu, ignora danos (evita agendar reload múltiplas vezes)
	if state == PlayerState.DEATH:
		return
	# Evita dano em cadeia durante o i-frame do HURT.
	if state == PlayerState.HURT:
		return
	# Aplica dano/vida
	health -= damage
	health = clamp(health, 0, max_health)
	GameManager.player_hp = health
	emit_signal("health_changed", health, max_health)
	# Morte: recarrega a cena inteira (reseta tudo)
	if health <= 0:
		_set_state(PlayerState.DEATH)
		call_deferred("emit_died_after_death")
		return
	# Entra em HURT (interrompível pelo input, como você já fez no _physics_process)
	_set_state(PlayerState.HURT)
	await get_tree().create_timer(0.35).timeout
	# Se o HURT foi cancelado por ataque/movimento/pulo, não força voltar pro idle/run
	if state != PlayerState.HURT:
		return
	apply_ground_state_by_input(is_on_floor())


func emit_died_after_death() -> void:
	# deixa a “animação de morte” acontecer (no seu caso é Hurt)
	await get_tree().create_timer(death_duration).timeout
	emit_signal("died")
