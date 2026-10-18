@tool
extends Entity

@export_group("Progress Bar Colors")
@export var fill_color: Color = Color(0.35, 0.68, 0.3, 1):
	set(value):
		fill_color = value
		_update_bar_colors()
@export var background_color: Color = Color(0.16, 0.14, 0.12, 1):
	set(value):
		background_color = value
		_update_bar_colors()


func _ready() -> void:
	_update_bar_colors()


func _update_bar_colors() -> void:
	if not is_node_ready():
		return
	var bar := get_node("ProgressBar") as ProgressBar
	var fill := bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	var background := bar.get_theme_stylebox("background").duplicate() as StyleBoxFlat
	fill.bg_color = fill_color
	background.bg_color = background_color
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", background)
