class_name SelectedPinObserver
extends Observer

const CABLE_SCENE: PackedScene = preload("res://Entities/e_cable.tscn")


func query() -> QueryBuilder:
	return q.with_all([C_Pin, C_SelectedPin]).on_added().on_removed()


func each(event: Variant, pin: Entity, payload: Variant = null) -> void:
	if not payload is C_SelectedPin:
		return
	var selection: C_SelectedPin = payload
	if event == Observer.Event.ADDED:
		var cable_entity := CABLE_SCENE.instantiate() as Entity
		var cable := C_Cable.new()
		cable.source = pin
		cable.cursor_position = (pin.get_node("CableAnchor") as Node2D).global_position
		cable_entity.add_component(cable)
		selection.cable = cable_entity
		cmd.add_entity(cable_entity)
	elif (event == Observer.Event.REMOVED and is_instance_valid(selection.cable)
		and _world.entities.has(selection.cable)):
		if (is_instance_valid(selection.target) and selection.target.enabled
			and _world.entities.has(selection.target) and selection.target.has_component(C_Pin)):
			var cable: C_Cable = selection.cable.get_component(C_Cable)
			cable.target = selection.target
			cable.state = C_Cable.State.CONNECTED
		else:
			cmd.remove_entity(selection.cable)
