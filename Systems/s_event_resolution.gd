class_name EventResolutionSystem
extends System


func query() -> QueryBuilder:
	return q.with_all([C_EventResolutionEvent])


func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var resolution: C_EventResolutionEvent = entity.get_component(C_EventResolutionEvent)
		_resolve(resolution)
		cmd.execute()


func _resolve(resolution: C_EventResolutionEvent) -> void:
	var event := resolution.location_event
	if (not is_instance_valid(event) or not _world.entities.has(event)
		or not event.has_component(C_LocationEvent) or not event.has_component(C_Lifetime)):
		_finish_cable(resolution.cable)
		return
	var data: C_LocationEvent = event.get_component(C_LocationEvent)
	var lifetime: C_Lifetime = event.get_component(C_Lifetime)
	if data.resolved or lifetime.remaining <= 0.0:
		_finish_cable(resolution.cable)
		return
	var pin := resolution.target
	if (not is_instance_valid(pin) or not pin.enabled or not _world.entities.has(pin)
		or not pin.has_component(C_Pin) or data.definition == null):
		if is_instance_valid(resolution.cable):
			cmd.remove_entity(resolution.cable)
		return
	var target_pin: C_Pin = pin.get_component(C_Pin)
	var option: LocationEventOption = data.definition.options.get(target_pin.location)
	var target := _find_location(target_pin.location)
	if option == null or target == null or target_pin.location == data.definition.location:
		if is_instance_valid(resolution.cable):
			cmd.remove_entity(resolution.cable)
		return
	if target.has_component(C_LocationCooldown):
		var cooldown: C_LocationCooldown = target.get_component(C_LocationCooldown)
		if cooldown.remaining > 0.0:
			if is_instance_valid(resolution.cable):
				cmd.remove_entity(resolution.cable)
			return
	for resource_type in option.resource_deltas:
		var request := C_ResourceChangeEvent.new()
		request.resource = resource_type
		request.delta = option.resource_deltas[resource_type]
		var change_event := Entity.new()
		change_event.name = "ResourceChangeEvent"
		change_event.add_component(request)
		cmd.add_entity(change_event)
	data.resolved = true
	_finish_cable(resolution.cable)
	cmd.add_custom(_start_cooldown.bind(target, option.cooldown_seconds))


func _finish_cable(entity: Entity) -> void:
	if is_instance_valid(entity) and _world.entities.has(entity) and not entity.has_component(C_Lifetime):
		cmd.add_component(entity, C_Lifetime.new())


func _start_cooldown(location: Entity, duration: float) -> void:
	if not is_instance_valid(location) or not _world.entities.has(location):
		return
	var cooldown: C_LocationCooldown
	if location.has_component(C_LocationCooldown):
		cooldown = location.get_component(C_LocationCooldown)
	else:
		cooldown = C_LocationCooldown.new()
		location.add_component(cooldown)
	cooldown.remaining = maxf(cooldown.remaining, maxf(duration, 0.0))


func _find_location(type: Enums.LocationType) -> Entity:
	for entity in _world.query.with_all([C_Location]).execute():
		var binding: C_Location = entity.get_component(C_Location)
		if binding.location == type:
			return entity
	return null
