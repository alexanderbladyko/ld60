extends Node2D

@export var play_area: Rect2 = Rect2(60.0, 20.0, 1040.0, 760.0)
@export_range(0.0, 200.0) var screen_margin: float = 32.0

@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	ECS.world = $World
	get_viewport().size_changed.connect(_center_game)
	_center_game()


func _center_game() -> void:
	var available := (get_viewport_rect().size - Vector2.ONE * screen_margin * 2.0).max(Vector2.ONE)
	var area_size := play_area.size.max(Vector2.ONE)
	var fit := minf(available.x / area_size.x, available.y / area_size.y)
	camera.position = play_area.get_center()
	camera.zoom = Vector2.ONE * fit
	camera.force_update_scroll()


func _process(delta: float) -> void:
	ECS.process(delta, "input")
	ECS.process(delta, "process")
	ECS.process(delta, "events")
