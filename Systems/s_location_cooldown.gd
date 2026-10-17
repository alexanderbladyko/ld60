class_name LocationCooldownSystem
extends System


func deps() -> Dictionary[int, Array]:
	return {Runs.Before: [PinSelectionSystem], Runs.After: []}


func query() -> QueryBuilder:
	return q.with_all([C_Location, C_LocationCooldown])


func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var cooldown: C_LocationCooldown = entity.get_component(C_LocationCooldown)
		cooldown.remaining = maxf(0.0, cooldown.remaining - maxf(delta, 0.0))
		if cooldown.remaining <= 0.000001:
			cooldown.remaining = 0.0
			cmd.remove_component(entity, C_LocationCooldown)
