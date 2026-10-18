class_name EventScoreObserver
extends Observer

@export_node_path("Label") var score_view: NodePath

var solved_problems: int = 0
var _counted_events: Dictionary[int, bool] = {}


func setup() -> void:
	_update_view()


func query() -> QueryBuilder:
	return q.with_all([C_LocationEvent]).on_changed([&"resolved"])


func each(_event: Variant, entity: Entity, _payload: Variant = null) -> void:
	var data: C_LocationEvent = entity.get_component(C_LocationEvent)
	var event_id := entity.get_instance_id()
	if not data.resolved or _counted_events.has(event_id):
		return
	_counted_events[event_id] = true
	solved_problems += 1
	_update_view()


func _update_view() -> void:
	var label := get_node(score_view) as Label
	label.text = "Problems solved: %d" % solved_problems
