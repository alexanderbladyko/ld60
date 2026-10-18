class_name LocationCooldownObserver
extends Observer


func sub_observers() -> Array[Array]:
	return [
		[q.with_all([C_Location, C_LocationCooldown]).on_match().on_unmatch().on_changed([
			&"remaining", &"location",
		]), _on_location_changed],
		[q.with_all([C_Pin]).on_match(), _on_pin_added],
	]


func _on_location_changed(event: Variant, entity: Entity, _payload: Variant) -> void:
	var excluded: Entity = entity if event == Observer.Event.UNMATCH else null
	var cooldown: C_LocationCooldown = entity.get_component(C_LocationCooldown)
	var remaining := cooldown.remaining if cooldown != null and entity != excluded else 0.0
	var indicator := entity.get_node_or_null("Cooldown") as Node2D
	if indicator != null:
		indicator.visible = remaining > 0.0
		var counter := indicator.get_node("Seconds") as Label
		counter.text = "%d s" % ceili(remaining) if remaining > 0.0 else ""
	for pin in _world.query.with_all([C_Pin]).execute():
		_refresh_pin(pin, entity if entity != excluded else null, excluded)


func _on_pin_added(_event: Variant, pin: Entity, _payload: Variant) -> void:
	_refresh_pin(pin)


func _refresh_pin(pin: Entity, changed: Entity = null, excluded: Entity = null) -> void:
	var binding: C_Pin = pin.get_component(C_Pin)
	var remaining := _cooldown_remaining(changed, binding.location)
	for location in _world.query.with_all([C_Location, C_LocationCooldown]).enabled().execute():
		if location != excluded:
			remaining = maxf(remaining, _cooldown_remaining(location, binding.location))
	var indicator := pin.get_node_or_null("CooldownIndicator") as Sprite2D
	if indicator != null:
		indicator.visible = remaining > 0.0
	var counter := pin.get_node_or_null("CooldownSeconds") as Label
	if counter != null:
		counter.visible = remaining > 0.0
		counter.text = "%d s" % ceili(remaining) if remaining > 0.0 else ""


func _cooldown_remaining(entity: Entity, location_type: Enums.LocationType) -> float:
	if (not is_instance_valid(entity) or not entity.enabled or not entity.has_component(C_Location)
		or not entity.has_component(C_LocationCooldown)):
		return 0.0
	var location: C_Location = entity.get_component(C_Location)
	var cooldown: C_LocationCooldown = entity.get_component(C_LocationCooldown)
	return maxf(cooldown.remaining, 0.0) if location.location == location_type else 0.0
