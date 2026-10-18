class_name ChaosVignetteObserver
extends Observer

@export_node_path("ColorRect") var vignette_view: NodePath
@export_range(0.0, 0.99) var start_ratio: float = 0.4
@export_range(0.0, 1.0) var max_opacity: float = 0.8


func query() -> QueryBuilder:
	return q.with_all([C_ChaosResource]).on_match().on_unmatch().on_changed([
		&"value", &"cap",
	])


func each(event: Variant, entity: Entity, _payload: Variant = null) -> void:
	if not entity is ResourceStorage:
		return
	var ratio := 0.0
	if event != Observer.Event.UNMATCH and entity.enabled:
		var chaos: C_ChaosResource = entity.get_component(C_ChaosResource)
		if chaos != null and chaos.cap > 0.0:
			ratio = chaos.value / chaos.cap
	var strength := clampf(inverse_lerp(start_ratio, 1.0, ratio), 0.0, 0.2)
	var vignette := get_node(vignette_view) as ColorRect
	(vignette.material as ShaderMaterial).set_shader_parameter("intensity", strength * max_opacity)
	vignette.visible = strength > 0.0
