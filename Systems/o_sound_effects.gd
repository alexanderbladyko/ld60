class_name SoundEffectsObserver
extends Observer

@export var ring_sound: AudioStream = preload("res://Sound/ring.mp3")
@export var cable_sound: AudioStream = preload("res://Sound/plugin.mp3")
@export_range(-40.0, 6.0) var ring_volume_db: float = -6.0
@export_range(-40.0, 6.0) var cable_volume_db: float = -6.0


func sub_observers() -> Array[Array]:
	return [
		[q.with_all([C_LocationEvent, C_Lifetime]).on_match(), _on_event_spawned],
		[q.with_all([C_Cable]).on_match(), _on_cable_event],
		[q.with_all([C_EventResolutionEvent]).on_match(), _on_cable_event],
	]


func _on_event_spawned(_event: Variant, entity: Entity, _payload: Variant) -> void:
	var data: C_LocationEvent = entity.get_component(C_LocationEvent)
	var lifetime: C_Lifetime = entity.get_component(C_Lifetime)
	if entity.enabled and data.definition != null and not data.resolved and lifetime.remaining > 0.0:
		_play(ring_sound, ring_volume_db)


func _on_cable_event(_event: Variant, entity: Entity, _payload: Variant) -> void:
	if entity.enabled:
		_play(cable_sound, cable_volume_db)


func _play(sound: AudioStream, volume_db: float) -> void:
	if sound == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = sound
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
