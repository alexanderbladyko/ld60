class_name LocationEventsSystem
extends System

const EVENT_SCENE: PackedScene = preload("res://Entities/e_location_event.tscn")

@export var catalog: LocationEventCatalog
@export_range(0.1, 300.0) var minimum_interval: float = 8.0
@export_range(0.1, 300.0) var maximum_interval: float = 18.0

var random := RandomNumberGenerator.new()
var time_until_next_event: float = 0.0


func setup() -> void:
	random.randomize()
	time_until_next_event = 2


func query() -> QueryBuilder:
	process_empty = true
	return q.with_all([C_Location])


func _run_process(delta: float) -> void:
	var locations: Array[Entity] = []
	locations.append_array(query().execute())
	process(locations, [], delta)


func process(locations: Array[Entity], _components: Array, delta: float) -> void:
	for entity in locations:
		if entity.has_component(C_LocationCooldown):
			var cooldown: C_LocationCooldown = entity.get_component(C_LocationCooldown)
			cooldown.remaining = maxf(0.0, cooldown.remaining - delta)
		if entity.has_component(C_ActiveLocationEvent):
			var active_event: C_ActiveLocationEvent = entity.get_component(C_ActiveLocationEvent)
			if not is_instance_valid(active_event.event) or not _world.entities.has(active_event.event):
				cmd.remove_component(entity, C_ActiveLocationEvent)
				var location: C_Location = entity.get_component(C_Location)
				_clear_request(location.location)
	_cleanup_events()
	time_until_next_event -= delta
	if time_until_next_event > 0.0:
		return
	time_until_next_event = _next_interval()
	var candidate := _choose_event(locations)
	if not candidate.is_empty():
		_spawn_event(candidate.definition, candidate.location)


func _next_interval() -> float:
	var low := maxf(minf(minimum_interval, maximum_interval), 0.1)
	var high := maxf(maxf(minimum_interval, maximum_interval), low)
	return random.randf_range(low, high)


func _choose_event(locations: Array[Entity]) -> Dictionary:
	if catalog == null:
		return {}
	var candidates: Array[Dictionary] = []
	var total_weight: float = 0.0
	for definition in catalog.events:
		if definition == null or definition.weight <= 0.0 or not is_finite(definition.weight):
			continue
		for entity in locations:
			var location: C_Location = entity.get_component(C_Location)
			if location.location != definition.location or entity.has_component(C_ActiveLocationEvent):
				continue
			if entity.has_component(C_LocationCooldown):
				var cooldown: C_LocationCooldown = entity.get_component(C_LocationCooldown)
				if cooldown.remaining > 0.0:
					continue
			candidates.append({"definition": definition, "location": entity})
			total_weight += definition.weight
			break
	if candidates.is_empty():
		return {}
	var roll := random.randf() * total_weight
	for candidate in candidates:
		roll -= candidate.definition.weight
		if roll < 0.0:
			return candidate
	return candidates[-1]


func _spawn_event(definition: LocationEventDefinition, location: Entity) -> void:
	var event := EVENT_SCENE.instantiate() as Entity
	var data := C_LocationEvent.new()
	data.definition = definition
	data.location = location
	event.add_component(data)
	var lifetime := C_Lifetime.new()
	lifetime.remaining = maxf(definition.effect_duration, 0.0)
	event.add_component(lifetime)
	cmd.add_entity(event)
	var active_event := C_ActiveLocationEvent.new()
	active_event.event = event
	cmd.add_component(location, active_event)
	if location.has_component(C_LocationCooldown):
		var cooldown: C_LocationCooldown = location.get_component(C_LocationCooldown)
		cooldown.remaining = maxf(definition.cooldown_seconds, 0.0)
	else:
		var cooldown := C_LocationCooldown.new()
		cooldown.remaining = maxf(definition.cooldown_seconds, 0.0)
		cmd.add_component(location, cooldown)
	for pin in _world.query.with_all([C_Pin]).execute():
		var binding: C_Pin = pin.get_component(C_Pin)
		if binding.location == definition.location and not pin.has_component(C_HelpNeeded):
			cmd.add_component(pin, C_HelpNeeded.new())


func _cleanup_events() -> void:
	for event in _world.query.with_all([C_LocationEvent]).execute():
		var data: C_LocationEvent = event.get_component(C_LocationEvent)
		if (not is_instance_valid(data.location) or not data.location.enabled
			or not _world.entities.has(data.location) or not data.location.has_component(C_Location)):
			cmd.remove_entity(event)
			if data.definition != null:
				_clear_request(data.definition.location)


func _clear_request(location: Enums.LocationType) -> void:
	for pin in _world.query.with_all([C_Pin]).execute():
		var binding: C_Pin = pin.get_component(C_Pin)
		if binding.location == location and pin.has_component(C_HelpNeeded):
			cmd.remove_component(pin, C_HelpNeeded)
