class_name LocationEventObserver
extends Observer

@export_node_path("PanelContainer") var event_view: NodePath


func query() -> QueryBuilder:
	return q.with_all([C_LocationEvent, C_Lifetime]).on_match().on_unmatch().on_changed([
		&"remaining", &"resolved",
	])


func each(event: Variant, entity: Entity, _payload: Variant = null) -> void:
	var excluded: Entity = entity if event == Observer.Event.UNMATCH else null
	var current: Entity
	var longest := 0.0
	var locations_needing_help: Dictionary = {}
	var candidates: Array[Entity] = []
	candidates.append_array(_world.query.with_all([C_LocationEvent, C_Lifetime]).enabled().execute())

	if excluded == null and entity.enabled and not candidates.has(entity):
		candidates.append(entity)
	for candidate in candidates:
		if candidate == excluded:
			continue
		var data: C_LocationEvent = candidate.get_component(C_LocationEvent)
		var lifetime: C_Lifetime = candidate.get_component(C_Lifetime)
		if data.definition == null or data.resolved or lifetime.remaining <= 0.000001:
			continue
		locations_needing_help[data.definition.location] = true
		if lifetime.remaining > longest:
			longest = lifetime.remaining
			current = candidate
	for pin in _world.query.with_all([C_Pin]).execute():
		var binding: C_Pin = pin.get_component(C_Pin)
		var needs_help := locations_needing_help.has(binding.location)
		if needs_help and not pin.has_component(C_HelpNeeded):
			cmd.add_component(pin, C_HelpNeeded.new())
		elif not needs_help and pin.has_component(C_HelpNeeded):
			cmd.remove_component(pin, C_HelpNeeded)
	_refresh_view(current)


func _refresh_view(current: Entity) -> void:
	var view := get_node_or_null(event_view) as Control
	if view == null:
		return
	var content := view.get_node("Margin/Content")
	var title := content.get_node("Hbox/LocationName") as Label
	var message := content.get_node("Hbox/Message") as Label
	var time_left := content.get_node("TimeLeft") as Label
	var bar := content.get_node("LifetimeBar") as ProgressBar
	if current == null:
		title.text = ""
		message.text = ""
		time_left.text = ""
		bar.value = 0.0
		view.hide()
		return
	var data: C_LocationEvent = current.get_component(C_LocationEvent)
	var lifetime: C_Lifetime = current.get_component(C_Lifetime)
	title.text = Enums.LocationType.keys()[data.definition.location].capitalize()
	message.text = data.definition.message
	time_left.text = "%.1f s" % lifetime.remaining
	bar.max_value = maxf(data.definition.effect_duration, 0.000001)
	bar.value = clampf(lifetime.remaining, 0.0, bar.max_value)
	view.show()
