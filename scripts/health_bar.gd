extends Node3D
# Health bar reutilizável para player e inimigos (HUD 3D com Sprite3D + SubViewport)

# Se true, a barra só fica visível após o nó sofrer dano (uso típico em inimigos)
@export var show_only_when_damaged: bool = false
# Se true, altera a cor da barra para vermelho (barra de inimigo)
@export var enemy_bar: bool = false
# Referência à ProgressBar que representa visualmente a vida
@onready var progress_bar: ProgressBar = $Sprite3D/SubViewport/Control/ProgressBar
# Nó pai que possui os dados de vida (player ou inimigo)
@onready var parent := get_parent()
# Guarda o último valor de vida para detectar se houve dano
var last_value : int = -1


func _ready() -> void:
	# Se for barra de inimigo, aplica a cor vermelha
	if enemy_bar:
		set_enemy_color()
	# Evita erros caso não exista nó pai
	if parent == null:
		return
	# Conecta ao sinal de mudança de vida do pai, se existir
	if parent.has_signal("health_changed"):
		parent.health_changed.connect(on_health_changed)
	# Sincroniza a barra imediatamente com os valores iniciais
	if "health" in parent and "max_health" in parent:
		on_health_changed(parent.health, parent.max_health)


func on_health_changed(current_health: int, max_health: int) -> void:
	# Atualiza limites e valor da barra
	progress_bar.max_value = max_health
	progress_bar.value = current_health
	# Controle de visibilidade
	if show_only_when_damaged:
		# Primeira atualização (spawn): mantém invisível
		if last_value == -1:
			visible = false
		# Se a vida diminuiu, exibe a barra
		elif current_health < last_value:
			visible = true
	else:
		# Player: barra sempre visível
		visible = true
	# Atualiza o último valor registrado
	last_value = current_health


func set_enemy_color() -> void:
	# Obtém o StyleBox do fill da ProgressBar
	var fill := progress_bar.get_theme_stylebox("fill")
	# Duplica o StyleBox para não afetar outras barras (player)
	if fill and fill is StyleBoxFlat:
		var fill_copy: StyleBoxFlat = fill.duplicate(true)
		fill_copy.bg_color = Color("#ff3b3b") # Vermelho para inimigos
		progress_bar.add_theme_stylebox_override("fill", fill_copy)
