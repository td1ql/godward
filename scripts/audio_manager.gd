extends Node

var streams := {}

func _ready() -> void:
	_load("click", "res://assets/audio/click.wav")
	_load("hit", "res://assets/audio/hit.wav")
	_load("victory", "res://assets/audio/victory.wav")
	_load("defeat", "res://assets/audio/defeat.wav")
	_load("heal", "res://assets/audio/heal.wav")

func _load(id: String, path: String) -> void:
	if ResourceLoader.exists(path):
		streams[id] = load(path)

func play(id: String) -> void:
	if not streams.has(id):
		return
	var p := AudioStreamPlayer.new()
	p.stream = streams[id]
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
