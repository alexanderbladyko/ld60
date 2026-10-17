class_name LocationEventResolutionSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_Cable])


func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var cable: C_Cable = entity.get_component(C_Cable)
		if cable.state != C_Cable.State.CONNECTED or cable.event_processed:
			continue
		_resolve(entity, cable)


func _resolve(entity: Entity, cable: C_Cable) -> void:
	var event := cable.location_event
	
	if not is_instance_valid(event) or not _world.entities.has(event):
		_finish_cable(entity, cable)
		return
		
	var data: C_LocationEvent = event.get_component(C_LocationEvent)
	if data.resolved:
		_finish_cable(entity, cable)
		return
		
	if (not is_instance_valid(cable.target) or not cable.target.enabled
		or not _world.entities.has(cable.target) or not cable.target.has_component(C_Pin)
		or not is_instance_valid(data.location) or not _world.entities.has(data.location)
		or not data.location.has_component(C_ActiveLocationEvent) or data.definition == null):
		cmd.remove_entity(entity)
		return
		
	var active_event: C_ActiveLocationEvent = data.location.get_component(C_ActiveLocationEvent)
	if active_event.event != event:
		_finish_cable(entity, cable)
		return
		
	var target_pin: C_Pin = cable.target.get_component(C_Pin)
	var option: LocationEventOption = data.definition.options.get(target_pin.location)
			
	var target := _find_location(target_pin.location)
	if option == null or target == null or target == data.location:
		cmd.remove_entity(entity)
		return
	var storage := _find_storage()
	if storage == null:
		return
		
	var changes: Array[Dictionary] = []
	for resource_type in option.resource_deltas:
		var stock := C_Resource.find_on(storage, resource_type)
		var amount: float = option.resource_deltas[resource_type]
		if stock == null or not is_finite(amount):
			return
		changes.append({"stock": stock, "value": clampf(stock.value + amount, 0.0, maxf(stock.cap, 0.0))})
		
	data.resolved = true
	_finish_cable(entity, cable)
	for change in changes:
		change.stock.value = change.value

	cmd.add_custom(_start_cooldown.bind(target, option.cooldown_seconds))
	cmd.remove_component(data.location, C_ActiveLocationEvent)
	
	for pin in _world.query.with_all([C_Pin]).execute():
		var binding: C_Pin = pin.get_component(C_Pin)
		if binding.location == data.definition.location and pin.has_component(C_HelpNeeded):
			cmd.remove_component(pin, C_HelpNeeded)
	cmd.remove_entity(event)


func _finish_cable(entity: Entity, cable: C_Cable) -> void:
	cable.event_processed = true
	if not entity.has_component(C_Lifetime):
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


func _find_storage() -> Entity:
	for entity in _world.entities:
		if is_instance_valid(entity) and entity.enabled and entity is ResourceStorage:
			return entity
	return null
