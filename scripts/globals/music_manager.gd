extends Node

var _player: AudioStreamPlayer
var _current_path: String = ""

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)

	# Continua tocando mesmo se você pausar o jogo (Game Over)
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_player.bus = "Master" # se você criar um bus "Music", troque aqui
	_player.volume_db = -8.0

func play_music(path: String, restart: bool = false) -> void:
	if path.is_empty():
		return

	# Não reinicia a mesma música quando muda de fase
	if not restart and _player.playing and _current_path == path:
		return

	var stream := load(path)
	if stream == null:
		push_warning("MusicManager: não consegui carregar " + path)
		return

	_current_path = path
	_player.stream = stream
	_player.play()

func stop_music() -> void:
	_player.stop()
	_current_path = ""
