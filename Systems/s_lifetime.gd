class_name LifetimeSystem
extends System


func query() -> QueryBuilder:
	return q.with_all([C_Lifetime])


func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var lifetime: C_Lifetime = entity.get_component(C_Lifetime)
		lifetime.remaining = maxf(0.0, lifetime.remaining - delta)
		if lifetime.remaining <= 0.000001:
			cmd.remove_entity(entity)
