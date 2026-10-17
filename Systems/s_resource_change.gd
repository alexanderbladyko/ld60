class_name ResourceChangeSystem
extends System

func query() -> QueryBuilder:
	return q.with_all([C_ResourceChangeEvent])


func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	var stocks: Dictionary[Enums.ResourceType, C_Resource] = {}
	for storage in _world.query.with_any([
		C_FoodResource, C_WoodResource, C_WeaponsResource, C_ManaResource, C_GoldResource,
	]).enabled().execute():
		if not storage is ResourceStorage:
			continue
		for component in storage.components.values():
			if component is C_Resource and not stocks.has(component.resource):
				stocks[component.resource] = component
		break
	for entity in entities:
		var event: C_ResourceChangeEvent = entity.get_component(C_ResourceChangeEvent)
		var stock: C_Resource = stocks.get(event.resource)
		if stock == null:
			continue
		stock.value = clampf(stock.value + event.delta, 0.0, maxf(stock.cap, 0.0))
