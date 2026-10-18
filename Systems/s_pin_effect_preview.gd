class_name PinEffectPreviewSystem
extends System

const EFFECT_VIEW: PackedScene = preload("res://Scenes/resource_effect_view.tscn")
const INCREASE_ICON: Texture2D = preload("res://Assets/Icons/effect_up.svg")
const DECREASE_ICON: Texture2D = preload("res://Assets/Icons/effect_down.svg")
const NEUTRAL_ICON: Texture2D = preload("res://Assets/Icons/effect_neutral.svg")

@export_range(0.01, 1000.0) var double_arrow_threshold: float = 10.0


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
		var signature := hash([option.message, option.resource_deltas, double_arrow_threshold]) if option != null else 0
		if state.option == option and state.signature == signature:
			continue
		state.option = option
		state.signature = signature
		var preview := pin.get_node("EffectPreview") as Control
		var message := preview.get_node("Content/Message") as Label
		var effects := preview.get_node("Content/Effects") as HFlowContainer
		for child in effects.get_children():
			effects.remove_child(child)
			child.queue_free()
		preview.visible = option != null
		message.text = option.message if option != null else ""
		message.visible = not message.text.is_empty()
		if option == null:
			continue
		for resource_type in range(ResourceIcons.TEXTURES.size()):
			var change: float = option.resource_deltas.get(resource_type, 0.0)
			if not is_finite(change) or is_zero_approx(change):
				continue
			var row := EFFECT_VIEW.instantiate() as Control
			var icon := row.get_node("Icon") as TextureRect
			icon.texture = ResourceIcons.TEXTURES[resource_type]
			var direction := row.get_node("Direction") as TextureRect
			direction.texture = INCREASE_ICON if change > 0.0 else DECREASE_ICON
			direction.modulate = Color(0.3, 0.9, 0.4) if change > 0.0 else Color(1.0, 0.3, 0.3)
			var second_direction := row.get_node("SecondDirection") as TextureRect
			second_direction.texture = direction.texture
			second_direction.modulate = direction.modulate
			second_direction.visible = absf(change) > double_arrow_threshold
			effects.add_child(row)
		if effects.get_child_count() == 0:
			var neutral := TextureRect.new()
			neutral.texture = NEUTRAL_ICON
			neutral.custom_minimum_size = Vector2(24, 24)
			neutral.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			neutral.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			neutral.mouse_filter = Control.MOUSE_FILTER_IGNORE
			effects.add_child(neutral)
