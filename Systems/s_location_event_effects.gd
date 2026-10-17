class_name LocationEventEffectsSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_LocationEvent, C_Lifetime])


func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	for entity in entities:
		var event: C_LocationEvent = entity.get_component(C_LocationEvent)
		var lifetime: C_Lifetime = entity.get_component(C_Lifetime)
		if event.resolved or event.definition == null or lifetime.remaining <= 0.0:
			continue
		var definition := event.definition
		if definition.effect.is_empty() or definition.effect_period <= 0.0 or not is_finite(definition.effect_period):
			continue
		event.effect_elapsed += minf(maxf(delta, 0.0), lifetime.remaining)
		var ticks := floori((event.effect_elapsed + 0.000001) / definition.effect_period)
		if ticks <= 0:
			continue
		event.effect_elapsed = maxf(0.0, event.effect_elapsed - ticks * definition.effect_period)
		for resource_type in definition.effect:
			var request := C_ResourceChangeEvent.new()
			request.resource = resource_type
			request.delta = definition.effect[resource_type] * ticks
			var change_event := Entity.new()
			change_event.name = "ResourceChangeEvent"
			change_event.add_component(request)
			cmd.add_entity(change_event)
