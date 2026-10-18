extends Control

static var show_game_over := false


func _ready() -> void:
	ECS.world = $World
	$Center/Content/GameOver.visible = show_game_over
	$Center/Content/Play.text = "Retry" if show_game_over else "Start"
	show_game_over = false
	$Center/Content/Play.pressed.connect(_start_game)
	$Center/Content/Play.grab_focus()


func _start_game() -> void:
	get_tree().change_scene_to_file("res://Scenes/game.tscn")
