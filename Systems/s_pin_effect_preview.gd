class_name PinEffectPreviewSystem
extends System

const EFFECT_VIEW: PackedScene = preload("res://Scenes/resource_effect_view.tscn")

@export_range(0.01, 1000.0) var double_arrow_threshold: float = 5.0


func query() -> QueryBuilder:
	return q.with_all([C_Pin])


func _run_process(delta: float) -> void:
	var pins: Array[Entity] = []
	pins.append_array(query().enabled().execute())
	process(pins, [], delta)


func process(pins: Array[Entity], _components: Array, _delta: float) -> void:
	var blocked_locations: Dictionary = {}
	for entity in _world.query.with_all([C_Location, C_LocationCooldown]).enabled().execute():
		var location: C_Location = entity.get_component(C_Location)
		var cooldown: C_LocationCooldown = entity.get_component(C_LocationCooldown)
		if cooldown.remaining > 0.0:
			blocked_locations[location.location] = true
	var selected: Entity
	var definition: LocationEventDefinition
	for pin in pins:
		if not pin.has_component(C_SelectedPin):
			continue
		selected = pin
		var binding: C_Pin = pin.get_component(C_Pin)
		var selection: C_SelectedPin = pin.get_component(C_SelectedPin)
		var event := selection.location_event
		if (blocked_locations.has(binding.location) or not is_instance_valid(event)
			or not _world.entities.has(event) or not event.has_component(C_LocationEvent)
			or not event.has_component(C_Lifetime)):
			break
		var data: C_LocationEvent = event.get_component(C_LocationEvent)
		var lifetime: C_Lifetime = event.get_component(C_Lifetime)
		if not data.resolved and lifetime.remaining > 0.0:
			definition = data.definition
		break
	for pin in pins:
		var binding: C_Pin = pin.get_component(C_Pin)
		var option: LocationEventOption
		if definition != null and pin != selected and not blocked_locations.has(binding.location):
			option = definition.options.get(binding.location)
		var state: C_PinEffectPreview = pin.get_component(C_PinEffectPreview)
		if state == null:
			state = C_PinEffectPreview.new()
			cmd.add_component(pin, state)
		var signature := hash([option.resource_deltas, double_arrow_threshold]) if option != null else 0
		if state.option == option and state.signature == signature:
			continue
		state.option = option
		state.signature = signature
		var preview := pin.get_node("EffectPreview") as HFlowContainer
		for child in preview.get_children():
			preview.remove_child(child)
			child.queue_free()
		preview.visible = option != null
		if option == null:
			continue
		for resource_type in range(ResourceIcons.TEXTURES.size()):
			var change: float = option.resource_deltas.get(resource_type, 0.0)
			if not is_finite(change) or is_zero_approx(change):
				continue
			var row := EFFECT_VIEW.instantiate() as Control
			var icon := row.get_node("Icon") as TextureRect
			icon.texture = ResourceIcons.TEXTURES[resource_type]
			var direction := row.get_node("Direction") as Label
			var arrow := "▲" if change > 0.0 else "▼"
			direction.text = arrow + arrow if absf(change) > double_arrow_threshold else arrow
			direction.add_theme_color_override("font_color",
				Color(0.3, 0.9, 0.4) if change > 0.0 else Color(1.0, 0.3, 0.3))
			preview.add_child(row)
		if preview.get_child_count() == 0:
			var neutral := Label.new()
			neutral.text = "—"
			neutral.mouse_filter = Control.MOUSE_FILTER_IGNORE
			neutral.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
			preview.add_child(neutral)
