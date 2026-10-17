class_name PinSelectionSystem
extends System

const SELECT_ACTION: StringName = &"Select"
const CANCEL_ACTION: StringName = &"Cancel"

var _actions: Array[Dictionary] = []


func _run_process(delta: float) -> void:
	process([], [], delta)


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
	if _actions.is_empty() and _selected_pin() == null and _pin_at(position) == null:
		return
	queue_action(action, position)
	get_viewport().set_input_as_handled()


func queue_action(action: StringName, position: Vector2) -> void:
	_actions.append({"action": action, "position": position})


func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	var selected := _selected_pin()
	if selected != null and (not selected.enabled or not selected.has_component(C_HelpNeeded)):
		cmd.remove_component(selected, C_SelectedPin)
		cmd.execute()
	for command in _actions:
		if command.action == CANCEL_ACTION:
			var pin := _selected_pin()
			if pin != null:
				cmd.remove_component(pin, C_SelectedPin)
		elif command.action == SELECT_ACTION:
			var pin := _pin_at(command.position)
			if pin != null:
				_select_pin(pin)
		cmd.execute()
	_actions.clear()


func _select_pin(pin: Entity) -> void:
	var selected := _selected_pin()
	if selected == null:
		if pin.has_component(C_HelpNeeded):
			var selection := C_SelectedPin.new()
			selection.location_event = _event_for_pin(pin)
			cmd.add_component(pin, selection)
		return
	if selected == pin:
		return
	var selection: C_SelectedPin = selected.get_component(C_SelectedPin)
	selection.target = pin
	var resolution := C_EventResolutionEvent.new()
	resolution.location_event = selection.location_event
	resolution.target = pin
	resolution.cable = selection.cable
	var event := Entity.new()
	event.name = "EventResolution"
	event.add_component(resolution)
	cmd.add_entity(event)
	cmd.remove_component(selected, C_SelectedPin)


func _selected_pin() -> Entity:
	for pin in _world.query.with_all([C_Pin, C_SelectedPin]).execute():
		return pin
	return null


func _event_for_pin(pin: Entity) -> Entity:
	var binding: C_Pin = pin.get_component(C_Pin)
	var current: Entity
	var longest := 0.0
	for entity in _world.query.with_all([C_LocationEvent, C_Lifetime]).enabled().execute():
		var data: C_LocationEvent = entity.get_component(C_LocationEvent)
		var lifetime: C_Lifetime = entity.get_component(C_Lifetime)
		if (data.definition != null and not data.resolved
			and data.definition.location == binding.location and lifetime.remaining > longest):
			longest = lifetime.remaining
			current = entity
	return current


func _pin_at(position: Vector2) -> Entity:
	var nearest: Entity
	var nearest_distance: float = INF
	for pin in _world.query.with_all([C_Pin]).enabled().execute():
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
