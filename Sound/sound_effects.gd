extends Node

const SOUND_OBSERVER: Script = preload("res://Systems/o_sound_effects.gd")


func _ready() -> void:
	ECS.world_changed.connect(_on_world_changed)
	if is_instance_valid(ECS.world):
		_on_world_changed(ECS.world)


func _on_world_changed(world: World) -> void:
	if not is_instance_valid(world):
		return
	for observer in world.observers:
		if observer is SoundEffectsObserver:
			return
	world.add_observer(SOUND_OBSERVER.new())
