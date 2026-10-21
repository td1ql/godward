extends Node

const SETTINGS_PATH := "user://settings.cfg"

var streams := {}
var muted := false

func _ready() -> void:
	_load_settings()
	_load("click", "res://assets/audio/click.wav")
	_load("hit", "res://assets/audio/hit.wav")
	_load("victory", "res://assets/audio/victory.wav")
	_load("defeat", "res://assets/audio/defeat.wav")
	_load("heal", "res://assets/audio/heal.wav")

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		muted = bool(cfg.get_value("audio", "muted", false))

func set_muted(v: bool) -> void:
	muted = v
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "muted", muted)
	cfg.save(SETTINGS_PATH)

func _load(id: String, path: String) -> void:
	if ResourceLoader.exists(path):
		streams[id] = load(path)

func play(id: String) -> void:
	if muted:
		return
	if not streams.has(id):
		return
	var p := AudioStreamPlayer.new()
	p.stream = streams[id]
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
