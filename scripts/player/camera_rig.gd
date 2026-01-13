extends Node3D
# Gerencia duas câmeras (background e foreground) renderizadas
# em SubViewports distintos, mantendo ambas sincronizadas
# com o ponto de câmera do player.

@onready var background_viewport: SubViewport = $base_camera/background_viewport_container/background_viewport
@onready var foreground_viewport: SubViewport = $base_camera/foreground_viewport_container/foreground_viewport

@onready var background_camera: Camera3D = $base_camera/background_viewport_container/background_viewport/background_camera
@onready var foreground_camera: Camera3D = $base_camera/foreground_viewport_container/foreground_viewport/foreground_camera


func _ready() -> void:
	# Ajusta o tamanho dos SubViewports para o tamanho da janela
	resize()


func resize() -> void:
	# Garante que background e foreground cubram toda a tela
	background_viewport.size = DisplayServer.window_get_size()
	foreground_viewport.size = DisplayServer.window_get_size()


func _process(_delta: float) -> void:
	# Mantém as duas câmeras alinhadas à câmera do player
	if GameManager.player:
		background_camera.global_transform = GameManager.player.camera_point.global_transform
		foreground_camera.global_transform = GameManager.player.camera_point.global_transform
