class_name ChaosSystem
extends System

signal chaos_limit_reached

@export_range(0.0, 100.0) var growth_per_empty_resource: float = 1
@export_range(0.0, 100.0) var decay_per_second: float = 0.2

var _game_over := false


func query() -> QueryBuilder:
	return q.with_all([C_ChaosResource])


func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	if _game_over:
		return
	for storage in entities:
		if not storage is ResourceStorage:
			continue
		var chaos: C_ChaosResource = storage.get_component(C_ChaosResource)
		var empty_resources := 0
		for component in storage.components.values():
			if (component is C_Resource and component.resource != Enums.ResourceType.CHAOS
				and component.value <= 0.0):
				empty_resources += 1
		var rate := growth_per_empty_resource * empty_resources if empty_resources > 0 else -decay_per_second
		var capacity := maxf(chaos.cap, 0.0)
		var next_value := chaos.value
		if next_value < capacity:
			next_value += rate * maxf(delta, 0.0)
		chaos.value = clampf(next_value, 0.0, capacity)
		if chaos.value >= capacity:
			_game_over = true
			chaos_limit_reached.emit()
			return
