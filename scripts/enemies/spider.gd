extends CharacterBody3D

# Controla as animações do inimigo
@onready var animation_player: AnimationPlayer = $SpiderPC1/AnimationPlayer
# Vida máxima do inimigo (configurável no editor)
@export var max_health: int = 50
# Vida atual do inimigo
var health: int


func _ready() -> void:
	# Inicializa a vida atual com o valor máximo
	health = max_health


func _physics_process(_delta: float) -> void:
	# Mantém a animação idle enquanto não houver outra ação
	animation_player.play("idle")


func take_damage(damage: int) -> void:
	# Reduz a vida com base no dano recebido
	health -= damage
	# Garante que a vida fique dentro do intervalo válido
	health = clamp(health, 0, max_health)
	# Log simples para depuração
	print("Enemy health:", health)
	# Se a vida acabar, elimina o inimigo
	if health <= 0:
		die()


func die() -> void:
	# Remove o inimigo da cena
	queue_free()
