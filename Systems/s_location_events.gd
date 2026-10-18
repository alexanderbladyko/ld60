class_name LocationEventsSystem
extends System

@export var catalog: LocationEventCatalog
@export_range(0.1, 300.0) var minimum_interval: float = 5.0
@export_range(0.1, 300.0) var maximum_interval: float = 12.0
@export_range(0.1, 300.0) var start_interval: float = 2.0

var random := RandomNumberGenerator.new()
var time_until_next_event: float = 0.0


func deps() -> Dictionary[int, Array]:
	return {Runs.After: [EventResolutionSystem], Runs.Before: []}


func setup() -> void:
	random.randomize()
	time_until_next_event = start_interval


func _run_process(delta: float) -> void:
	process([], [], delta)


func process(_entities: Array[Entity], _components: Array, delta: float) -> void:
	time_until_next_event -= delta
	if time_until_next_event > 0.0:
		return
	var low := maxf(minf(minimum_interval, maximum_interval), 0.1)
	var high := maxf(maxf(minimum_interval, maximum_interval), low)
	time_until_next_event = random.randf_range(low, high)
	var definition := _choose_event()
	if definition != null:
		_spawn_event(definition)


func _choose_event() -> LocationEventDefinition:
	if catalog == null:
		return null
	var occupied_locations: Dictionary = {}
	
	for entity in _world.query.with_all([C_LocationEvent, C_Lifetime]).enabled().execute():
		var event: C_LocationEvent = entity.get_component(C_LocationEvent)
		var lifetime: C_Lifetime = entity.get_component(C_Lifetime)
		if event.definition != null and not event.resolved and lifetime.remaining > 0.0:
			occupied_locations[event.definition.location] = true

	for entity in _world.query.with_all([C_Location, C_LocationCooldown]).enabled().execute():
		var cooldown: C_LocationCooldown = entity.get_component(C_LocationCooldown)
		if cooldown.remaining > 0.0:
			var location: C_Location = entity.get_component(C_Location)
			occupied_locations[location.location] = true

	var candidates: Array[LocationEventDefinition] = []
	var total_weight := 0.0
	for definition in catalog.events:
		if (definition == null or not is_finite(definition.weight) or definition.weight <= 0.0
			or occupied_locations.has(definition.location)):
			continue
		candidates.append(definition)
		total_weight += definition.weight

	if candidates.is_empty():
		return null

	var roll := random.randf() * total_weight
	for definition in candidates:
		roll -= definition.weight
		if roll < 0.0:
			return definition
	return candidates.back()


func _spawn_event(definition: LocationEventDefinition) -> void:
	var event := LocationEvent.new()
	var data := C_LocationEvent.new()
	data.definition = definition
	event.add_component(data)
	var lifetime := C_Lifetime.new()
	lifetime.remaining = maxf(definition.effect_duration, 0.0)
	event.add_component(lifetime)
	cmd.add_entity(event)
