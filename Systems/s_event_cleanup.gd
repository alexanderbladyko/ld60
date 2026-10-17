class_name EventCleanupSystem
extends System


func query() -> QueryBuilder:
	return q.with_any([C_ResourceChangeEvent, C_EventResolutionEvent])


func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		cmd.remove_entity(entity)
