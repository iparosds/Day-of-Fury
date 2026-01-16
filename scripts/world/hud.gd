extends Control

# Label que mostra o número de vidas restantes
@onready var lives_label: Label = $LivesLabel


func _ready() -> void:
	# Atualiza o HUD ao iniciar a cena,
	update_lives()


func update_lives() -> void:
	# Atualiza o texto do HUD com o número de vidas restantes
	lives_label.text = "Lives: " + str(GameManager.player_lives)
