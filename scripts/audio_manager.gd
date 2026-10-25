extends Node

const SETTINGS_PATH := "user://settings.cfg"
const BGM_DIR := "res://assets/audio/bgm/%s.ogg"
const BGM_DB := -14.0
# 每个音效的音量（0 = 原始，越负越小）
const SFX_DB := {
	"draw": -16.0,
	"play": -11.0,
	"click": -8.0,
	"hit": -5.0,
	"attack": -5.0,
	"hurt": -6.0,
	"heal": -6.0,
	"victory": -2.0,
	"defeat": -2.0,
}
const SILENT_DB := -45.0

var streams := {}
var muted := false

var bgm_player: AudioStreamPlayer
var bgm_muted := false
var master_muted := false
var _bgm_id := ""
var _fade: Tween


func _ready() -> void:
	_load_settings()
	_load("click", "res://assets/audio/click.wav")
	_load("hit", "res://assets/audio/hit.wav")
	_load("victory", "res://assets/audio/victory.wav")
	_load("defeat", "res://assets/audio/defeat.wav")
	_load("heal", "res://assets/audio/heal.wav")
	_load("attack", "res://assets/audio/attack.wav")
	_load("hurt", "res://assets/audio/hurt.wav")
	_load("draw", "res://assets/audio/draw.wav")
	_load("play", "res://assets/audio/play.wav")

	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = SILENT_DB
	add_child(bgm_player)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		muted = bool(cfg.get_value("audio", "muted", false))
		bgm_muted = bool(cfg.get_value("audio", "bgm_muted", false))
		master_muted = bool(cfg.get_value("audio", "master_muted", false))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "muted", muted)
	cfg.set_value("audio", "bgm_muted", bgm_muted)
	cfg.set_value("audio", "master_muted", master_muted)
	cfg.save(SETTINGS_PATH)


# 音效开关（只管音效）

# 总开关：一次关掉音效和音乐
func set_master_muted(v: bool) -> void:
	master_muted = v
	set_muted(v)
	set_bgm_muted(v)

func set_muted(v: bool) -> void:
	muted = v
	_save_settings()


func set_bgm_muted(v: bool) -> void:
	bgm_muted = v
	_save_settings()
	if v:
		_stop_now()
	elif _bgm_id != "":
		var id := _bgm_id
		_bgm_id = ""
		play_bgm(id, 0.4)


func _load(id: String, path: String) -> void:
	if ResourceLoader.exists(path):
		streams[id] = load(path)


func play(id: String) -> void:
	if master_muted or muted:
		return
	if not streams.has(id):
		return
	var p := AudioStreamPlayer.new()
	p.stream = streams[id]
	p.volume_db = float(SFX_DB.get(id, 0.0))
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


# ===== BGM =====

func play_bgm(id: String, fade: float = 1.2) -> void:
	if master_muted or bgm_muted:
		_stop_now()
		_bgm_id = id
		return
	if id == _bgm_id:
		return
	var path: String = BGM_DIR % id
	_bgm_id = id
	if bgm_muted:
		_stop_now()
		return
	if not ResourceLoader.exists(path):
		return

	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true

	_kill_tween()
	_fade = create_tween()
	_fade.tween_property(bgm_player, "volume_db", SILENT_DB, fade * 0.5)
	_fade.tween_callback(func() -> void:
		bgm_player.stream = stream
		bgm_player.volume_db = SILENT_DB
		bgm_player.play()
	)
	_fade.tween_property(bgm_player, "volume_db", BGM_DB, fade * 0.5)


func stop_bgm(fade: float = 1.0) -> void:
	_bgm_id = ""
	_kill_tween()
	if not bgm_player.playing:
		return
	_fade = create_tween()
	_fade.tween_property(bgm_player, "volume_db", SILENT_DB, fade)
	_fade.tween_callback(bgm_player.stop)


func _stop_now() -> void:
	_kill_tween()
	bgm_player.stop()
	bgm_player.volume_db = SILENT_DB


func _kill_tween() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
