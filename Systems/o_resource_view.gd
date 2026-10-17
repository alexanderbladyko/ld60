class_name ResourceViewObserver
extends Observer

var _resource_types: Array = [
	C_Resource, C_FoodResource, C_WoodResource, C_WeaponsResource, C_ManaResource, C_GoldResource,
]

func sub_observers() -> Array[Array]:
	return [
		[q.with_any(_resource_types).on_match().on_unmatch().on_added().on_removed().on_changed([
			&"value", &"cap", &"resource",
		]), _on_source_changed],
		[q.with_all([C_ResourceView]).on_match().on_unmatch().on_changed([
			&"resource",
		]), _on_view_changed],
	]


func _on_source_changed(event: Variant, entity: Entity, _payload: Variant) -> void:
	if not entity is ResourceStorage:
		return
	var excluded: Entity = entity if event == Observer.Event.UNMATCH else null
	var changed: Entity = entity if event != Observer.Event.UNMATCH else null
	for view in _world.query.with_all([C_ResourceView]).execute():
		_refresh_view(view, changed, excluded)


func _on_view_changed(event: Variant, entity: Entity, _payload: Variant) -> void:
	if event == Observer.Event.UNMATCH:
		entity.set("visible", false)
		return
	_refresh_view(entity)


func _refresh_view(view: Entity, changed: Entity = null, excluded: Entity = null) -> void:
	var binding: C_ResourceView = view.get_component(C_ResourceView)
	var source := _find_source(binding, changed, excluded)
	var title := view.get_node("Header/ResourceName") as Label
	var counter := view.get_node("Header/Amount") as Label
	var bar := view.get_node("ProgressBar") as ProgressBar
	var control := view.get_node(".") as Control
	title.text = Enums.ResourceType.keys()[binding.resource].capitalize()
	if source == null:
		bar.value = 0.0
		bar.max_value = 1.0
		counter.text = "0 / 0"
		control.hide()
		return
	var resource := C_Resource.find_on(source, binding.resource)
	var capacity := maxf(resource.cap, 0.0)
	var amount := clampf(resource.value, 0.0, capacity)
	bar.max_value = capacity if capacity > 0.0 else 1.0
	bar.value = amount
	counter.text = "%s / %s" % [
		String.num(amount, 1).trim_suffix(".0"), String.num(capacity, 1).trim_suffix(".0"),
	]
	control.show()


func _find_source(binding: C_ResourceView, changed: Entity, excluded: Entity) -> Entity:
	if changed != excluded and _matches(changed, binding):
		return changed
	for entity in _world.query.with_any(_resource_types).execute():
		if entity != excluded and _matches(entity, binding):
			return entity
	return null


func _matches(entity, binding: C_ResourceView) -> bool:
	if not is_instance_valid(entity) or not entity.enabled or not entity is ResourceStorage:
		return false
	return C_Resource.find_on(entity, binding.resource) != null
