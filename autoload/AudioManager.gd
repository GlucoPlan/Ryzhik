extends Node

# ─────────────────────────────────────────
#  AudioManager.gd  —  Autoload синглтон
#  Централизованное управление звуком.
#  Подключить: Project > Autoload, имя "AudioManager"
# ─────────────────────────────────────────

# Пути к звуковым файлам (положи в assets/sounds/)
const SOUNDS := {
	"tap":        "res://assets/sounds/tap.ogg",
	"correct":    "res://assets/sounds/correct.ogg",
	"wrong":      "res://assets/sounds/wrong.ogg",
	"star":       "res://assets/sounds/star.ogg",
	"glucometer": "res://assets/sounds/glucometer.ogg",
	"juice":      "res://assets/sounds/juice.ogg",
	"complete":   "res://assets/sounds/complete.ogg",
}

const MUSIC := {
	"menu":    "res://assets/sounds/music_menu.ogg",
	"episode": "res://assets/sounds/music_episode.ogg",
}

var _sfx_player:   AudioStreamPlayer
var _music_player: AudioStreamPlayer

func _ready() -> void:
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "SFX"
	add_child(_sfx_player)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.volume_db = -6.0
	add_child(_music_player)

func play_sfx(sound_name: String) -> void:
	if not GameState.settings.get("sound_on", true):
		return
	if not SOUNDS.has(sound_name):
		push_warning("AudioManager: звук '%s' не найден" % sound_name)
		return
	var stream := load(SOUNDS[sound_name]) as AudioStream
	if stream:
		_sfx_player.stream = stream
		_sfx_player.play()

func play_music(track_name: String) -> void:
	if not GameState.settings.get("music_on", true):
		return
	if not MUSIC.has(track_name):
		return
	var stream := load(MUSIC[track_name]) as AudioStream
	if stream and _music_player.stream != stream:
		_music_player.stream = stream
		_music_player.play()

func stop_music() -> void:
	_music_player.stop()

func fade_out_music(duration: float = 1.0) -> void:
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", -80.0, duration)
	tween.tween_callback(_music_player.stop)
