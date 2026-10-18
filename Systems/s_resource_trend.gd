class_name ResourceTrendSystem
extends System

@export_range(0.01, 1000.0) var double_arrow_threshold: float = 5.0
@export_range(0.1, 10.0) var sample_window: float = 2.0


func query() -> QueryBuilder:
	return q.with_all([C_ResourceView, C_ResourceTrend])


func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	var stocks: Dictionary[Enums.ResourceType, C_Resource] = {}
	for storage in _world.query.with_any([
		C_Resource, C_FoodResource, C_WoodResource, C_WeaponsResource, C_ManaResource, C_GoldResource, C_ChaosResource,
	]).enabled().execute():
		if not storage is ResourceStorage:
			continue
		for component in storage.components.values():
			if component is C_Resource and not stocks.has(component.resource):
				stocks[component.resource] = component
		break
	for view in entities:
		var binding: C_ResourceView = view.get_component(C_ResourceView)
		var trend: C_ResourceTrend = view.get_component(C_ResourceTrend)
		var indicator := view.get_node("Content/Header/Trend") as Label
		var source: C_Resource = stocks.get(binding.resource)
		if source == null or source != trend.source or binding.resource != trend.last_resource:
			trend.source = source
			trend.last_resource = binding.resource
			trend.previous_value = source.value if source != null else 0.0
			trend.elapsed = 0.0
			trend.samples.clear()
			indicator.text = ""
			continue
		trend.elapsed += maxf(delta, 0.0)
		var change := source.value - trend.previous_value
		trend.previous_value = source.value
		if is_finite(change) and not is_zero_approx(change):
			trend.samples.append(Vector2(trend.elapsed, change))
		var window := maxf(sample_window, 0.001)
		while not trend.samples.is_empty() and trend.elapsed - trend.samples[0].x >= window:
			trend.samples.pop_front()
		var net_change := 0.0
		for sample in trend.samples:
			net_change += sample.y
		var rate := net_change / maxf(minf(window, trend.elapsed), 0.001)
		if is_zero_approx(rate):
			indicator.text = ""
			continue
		var arrow := "▶" if rate > 0.0 else "◀"
		indicator.text = arrow + arrow if absf(rate) > double_arrow_threshold else arrow
		indicator.add_theme_color_override("font_color",
			Color(0.3, 0.9, 0.4) if rate > 0.0 else Color(1.0, 0.3, 0.3))
