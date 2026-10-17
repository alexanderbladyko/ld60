class_name LocationEventOption
extends Resource

@export_multiline var message: String = ""
@export var resource_deltas: Dictionary[Enums.ResourceType, float] = {}
@export_range(0.0, 600.0) var cooldown_seconds: float = 20.0
