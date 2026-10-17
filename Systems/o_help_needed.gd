class_name HelpNeededObserver
extends Observer


func query() -> QueryBuilder:
	return q.with_all([C_Pin, C_HelpNeeded]).on_match().on_unmatch()


func each(event: Variant, entity: Entity, _payload: Variant = null) -> void:
	var animation := entity.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation == null:
		return
	if event == Observer.Event.MATCH:
		animation.play(&"blink")
	else:
		animation.play(&"RESET")
	animation.advance(0.0)
