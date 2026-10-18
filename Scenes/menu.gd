extends Control

static var show_game_over := false
static var solved_problems: int = 0


func _ready() -> void:
	ECS.world = $World
	$Content/GameOver.visible = show_game_over
	$Content/Results.visible = show_game_over
	$Content/Results.text = "You solved %d customer problem%s!" % [
		solved_problems, "" if solved_problems == 1 else "s",
	]
	$Content/Play.text = "Retry" if show_game_over else "Start"
	show_game_over = false
	solved_problems = 0
	$Content/Play.pressed.connect(_start_game)
	$Content/Play.grab_focus()


func _start_game() -> void:
	get_tree().change_scene_to_file("res://Scenes/game.tscn")
