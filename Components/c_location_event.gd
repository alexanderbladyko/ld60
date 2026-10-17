class_name C_LocationEvent
extends Component

@export var definition: LocationEventDefinition
var resolved: bool = false:
	set(new_value):
		if resolved == new_value:
			return
		var previous := resolved
		resolved = new_value
		property_changed.emit(self, "resolved", previous, resolved)
var effect_elapsed: float = 0.0
