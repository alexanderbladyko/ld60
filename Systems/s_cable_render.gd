class_name CableRenderSystem
extends System


func query() -> QueryBuilder:
	return q.with_all([C_Cable])


func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var cable: C_Cable = entity.get_component(C_Cable)
		if not _valid_endpoint(cable.source):
			cmd.remove_entity(entity)
			continue
		if cable.state == C_Cable.State.CONNECTED and not _valid_endpoint(cable.target):
			cmd.remove_entity(entity)
			continue
		var source := cable.source.get_node("CableAnchor") as Node2D
		var endpoint := cable.cursor_position
		if cable.state == C_Cable.State.CONNECTED:
			var target := cable.target.get_node("CableAnchor") as Node2D
			endpoint = target.global_position
		var line := entity.get_node("Line2D") as Line2D
		var points := PackedVector2Array()
		var sag := minf(cable.sag, source.global_position.distance_to(endpoint) * 0.25)
		for index in range(25):
			var weight := float(index) / 24.0
			var position := source.global_position.lerp(endpoint, weight)
			position.y += sin(weight * PI) * sag
			points.append(line.to_local(position))
		line.points = points
		line.width = cable.width
		line.default_color = cable.color


func _valid_endpoint(entity) -> bool:
	return (is_instance_valid(entity) and entity.enabled and _world.entities.has(entity)
		and entity.has_component(C_Pin) and entity.has_node("CableAnchor"))
