extends Node

# ─────────────────────────────────────────
#  GameState.gd  —  Autoload синглтон
#  Хранит весь прогресс игрока.
#  Подключить: Project > Project Settings >
#  Autoload > путь к этому файлу, имя "GameState"
# ─────────────────────────────────────────

const SAVE_PATH := "user://save.cfg"

# Прогресс по эпизодам: { "ep01": { "stars": 3, "sticker": true }, ... }
var episodes: Dictionary = {}

# Открытые наклейки для альбома (список id)
var stickers: Array = []

# Общие настройки
var settings: Dictionary = {
	"device_type": "pump",   # "pump" или "pen" — помпа или шприц-ручка
	"sound_on": true,
	"music_on": true,
}

signal progress_changed
signal sticker_earned(sticker_id: String)

# ── Инициализация ──────────────────────────────────────────────────────────────

func _ready() -> void:
	load_progress()

# ── Работа с эпизодами ─────────────────────────────────────────────────────────

func complete_episode(ep_id: String, stars: int, sticker_id: String = "") -> void:
	var prev_stars: int = get_stars(ep_id)

	# Сохраняем только если результат лучше предыдущего
	if stars > prev_stars:
		episodes[ep_id] = {
			"stars": stars,
			"sticker": sticker_id != "",
			"sticker_id": sticker_id,
		}
		save_progress()
		emit_signal("progress_changed")

	if sticker_id != "" and sticker_id not in stickers:
		stickers.append(sticker_id)
		save_progress()
		emit_signal("sticker_earned", sticker_id)

func is_episode_completed(ep_id: String) -> bool:
	return episodes.has(ep_id)

func get_stars(ep_id: String) -> int:
	return episodes.get(ep_id, {}).get("stars", 0)

func is_episode_unlocked(ep_id: String, all_episode_ids: Array) -> bool:
	# Первый эпизод всегда открыт
	var idx := all_episode_ids.find(ep_id)
	if idx <= 0:
		return true
	# Остальные открываются после прохождения предыдущего
	var prev_id: String = all_episode_ids[idx - 1]
	return is_episode_completed(prev_id)

func get_total_stars() -> int:
	var total := 0
	for ep in episodes.values():
		total += ep.get("stars", 0)
	return total

# ── Сохранение / загрузка ──────────────────────────────────────────────────────

func save_progress() -> void:
	var cfg := ConfigFile.new()

	for ep_id in episodes:
		var ep: Dictionary = episodes[ep_id]
		cfg.set_value("episodes", ep_id, ep)

	cfg.set_value("meta", "stickers", stickers)
	cfg.set_value("meta", "settings", settings)

	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_error("GameState: не удалось сохранить прогресс, код ошибки: %d" % err)

func load_progress() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		# Первый запуск — файла ещё нет, это нормально
		return

	for ep_id in cfg.get_section_keys("episodes"):
		episodes[ep_id] = cfg.get_value("episodes", ep_id, {})

	stickers = cfg.get_value("meta", "stickers", [])
	settings  = cfg.get_value("meta", "settings", settings)

func reset_progress() -> void:
	episodes.clear()
	stickers.clear()
	save_progress()
	emit_signal("progress_changed")
