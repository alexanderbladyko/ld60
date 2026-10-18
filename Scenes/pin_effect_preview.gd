extends PanelContainer


func _ready() -> void:
	$Content.minimum_size_changed.connect(reset_size)
