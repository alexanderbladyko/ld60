class_name LocationEventObserver
extends Observer

@export_node_path("PanelContainer") var event_view: NodePath

var _current_event: Entity


func sub_observers() -> Array[Array]:
	return [
		[q.with_all([C_LocationEvent, C_Lifetime]).on_match().on_unmatch().on_changed([
			&"remaining", &"message_dismissed",
		]), _on_event_changed],
		[q.with_all([C_Pin]).on_event(&"pin_selected"), _on_pin_selected],
	]


func _on_event_changed(event: Variant, entity: Entity, _payload: Variant) -> void:
	var preferred: Entity = entity if event == Observer.Event.MATCH else null
	var excluded: Entity = entity if event == Observer.Event.UNMATCH else null
	_refresh_view(preferred, excluded)


func _on_pin_selected(_event: Variant, pin: Entity, _payload: Variant) -> void:
	var binding: C_Pin = pin.get_component(C_Pin)
	for entity in _world.query.with_all([C_LocationEvent]).execute():
		var data: C_LocationEvent = entity.get_component(C_LocationEvent)
		if data.definition != null and data.definition.location == binding.location:
			data.message_dismissed = true


func _refresh_view(preferred: Entity = null, excluded: Entity = null) -> void:
	var view := get_node_or_null(event_view) as Control
	if view == null:
		return
	if _can_display(preferred, excluded):
		_current_event = preferred
	if not _can_display(_current_event, excluded):
		_current_event = null
		for candidate in _world.query.with_all([C_LocationEvent, C_Lifetime]).execute():
			if _can_display(candidate, excluded):
				_current_event = candidate
	var content := view.get_node("Margin/Content")
	var title := content.get_node("LocationName") as Label
	var message := content.get_node("Message") as Label
	var time_left := content.get_node("TimeLeft") as Label
	var bar := content.get_node("LifetimeBar") as ProgressBar
	if _current_event == null:
		title.text = ""
		message.text = ""
		time_left.text = ""
		bar.value = 0.0
		view.hide()
		return
	var data: C_LocationEvent = _current_event.get_component(C_LocationEvent)
	var lifetime: C_Lifetime = _current_event.get_component(C_Lifetime)
	title.text = Enums.LocationType.keys()[data.definition.location].capitalize()
	message.text = data.definition.message
	time_left.text = "%.1f s" % lifetime.remaining
	bar.max_value = maxf(data.definition.effect_duration, 0.000001)
	bar.value = clampf(lifetime.remaining, 0.0, bar.max_value)
	view.show()


func _can_display(entity: Entity, excluded: Entity) -> bool:
	if (not is_instance_valid(entity) or entity == excluded or not entity.enabled
		or not _world.entities.has(entity) or not entity.has_component(C_LocationEvent)
		or not entity.has_component(C_Lifetime)):
		return false
	var data: C_LocationEvent = entity.get_component(C_LocationEvent)
	var lifetime: C_Lifetime = entity.get_component(C_Lifetime)
	return (data.definition != null and not data.resolved and not data.message_dismissed
		and lifetime.remaining > 0.000001)
