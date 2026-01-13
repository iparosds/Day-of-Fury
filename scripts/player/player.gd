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
enum PlayerState { IDLE, RUN, JUMP, ATTACK }

@onready var animation_player: AnimationPlayer = $visuals/robot/AnimationPlayer
@onready var visuals: Node3D = $visuals
# ponto usado por câmera externa
@onready var camera_point: Node3D = $camera_point 

# Estado atual do player
var state: int = PlayerState.IDLE
# Direção de movimento calculada a partir do input
var move_dir: Vector3 = Vector3.ZERO
# Cache do estado de chão do frame anterior (para detectar transições)
var was_on_floor: bool = false


func _ready() -> void:
	# Registra o player no GameManager
	GameManager.set_player(self)
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
	# Se o ataque acabou (animação não é mais Attack1), corrige para Idle/Run
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
# separando rotação da lógica de movimento (fica mais estável e legível).
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
		_:
			animation_player.play("Idle")
