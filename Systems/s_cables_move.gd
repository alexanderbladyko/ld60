class_name CablesMoveSystem
extends System

const CABLE_SCENE: PackedScene = preload("res://Entities/e_cable.tscn")
const SELECT_ACTION: StringName = &"Select"
const CANCEL_ACTION: StringName = &"Cancel"

var active_cable: Entity
var _actions: Array[Dictionary] = []


func query() -> QueryBuilder:
	process_empty = true
	return q.with_all([C_Pin])


func _run_process(delta: float) -> void:
	var pins: Array[Entity] = []
	pins.append_array(query().execute())
	process(pins, [], delta)


func _unhandled_input(event: InputEvent) -> void:
	if not active or paused or _world == null or _world != ECS.world:
		return
	var action: StringName
	if event.is_action_pressed(CANCEL_ACTION):
		action = CANCEL_ACTION
	elif event.is_action_pressed(SELECT_ACTION):
		action = SELECT_ACTION
	else:
		return
	var pointer := get_viewport().get_mouse_position()
	if event is InputEventMouseButton:
		pointer = event.position
	var position := get_viewport().get_canvas_transform().affine_inverse() * pointer
	if _actions.is_empty() and not is_instance_valid(active_cable) and _pin_at(position) == null:
		return
	queue_action(action, position)
	get_viewport().set_input_as_handled()


func queue_action(action: StringName, position: Vector2) -> void:
	_actions.append({"action": action, "position": position})


func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	_validate_active_cable()
	for command in _actions:
		if command.action == CANCEL_ACTION:
			cancel_active_cable()
		elif command.action == SELECT_ACTION:
			var pin := _pin_at(command.position)
			if pin == null:
				continue
			_world.emit_event(&"pin_selected", pin)
			if is_instance_valid(active_cable):
				_connect_to(pin)
			elif pin.has_component(C_HelpNeeded):
				_start_cable(pin, command.position)
	_actions.clear()
	if is_instance_valid(active_cable):
		var cable: C_Cable = active_cable.get_component(C_Cable)
		cable.cursor_position = (get_viewport().get_canvas_transform().affine_inverse()
			* get_viewport().get_mouse_position())


func cancel_active_cable() -> void:
	if is_instance_valid(active_cable):
		cmd.remove_entity(active_cable)
	active_cable = null


func _start_cable(pin: Entity, position: Vector2) -> void:
	var entity := CABLE_SCENE.instantiate() as Entity
	var cable := C_Cable.new()
	cable.source = pin
	cable.cursor_position = position
	entity.add_component(cable)
	active_cable = entity
	cmd.add_entity(entity)


func _connect_to(pin: Entity) -> void:
	var cable: C_Cable = active_cable.get_component(C_Cable)
	if cable.source == pin:
		return
	var source_pin: C_Pin = cable.source.get_component(C_Pin)
	for location in _world.query.with_all([C_Location, C_ActiveLocationEvent]).execute():
		var binding: C_Location = location.get_component(C_Location)
		if binding.location == source_pin.location:
			var active_event: C_ActiveLocationEvent = location.get_component(C_ActiveLocationEvent)
			cable.location_event = active_event.event
			break
	cable.target = pin
	cable.state = C_Cable.State.CONNECTED
	active_cable = null


func _validate_active_cable() -> void:
	if not is_instance_valid(active_cable):
		active_cable = null
		return
	if not _world.entities.has(active_cable):
		active_cable = null
		return
	var cable: C_Cable = active_cable.get_component(C_Cable)
	if (not is_instance_valid(cable.source) or not _world.entities.has(cable.source)
		or not cable.source.enabled or not cable.source.has_component(C_HelpNeeded)):
		cancel_active_cable()


func _pin_at(position: Vector2) -> Entity:
	var nearest: Entity
	var nearest_distance: float = INF
	for pin in _world.query.with_all([C_Pin]).execute():
		var collision := pin.get_node_or_null("InputArea/CollisionShape2D") as CollisionShape2D
		if collision == null or collision.disabled or not collision.is_visible_in_tree():
			continue
		var circle := collision.shape as CircleShape2D
		if circle == null or collision.to_local(position).length_squared() > circle.radius * circle.radius:
			continue
		var distance := collision.global_position.distance_squared_to(position)
		if distance < nearest_distance:
			nearest = pin
			nearest_distance = distance
	return nearest
