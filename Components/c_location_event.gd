class_name C_LocationEvent
extends Component

@export var definition: LocationEventDefinition
var location: Entity
var resolved: bool = false
var message_dismissed: bool = false:
	set(new_value):
		if message_dismissed == new_value:
			return
		var previous := message_dismissed
		message_dismissed = new_value
		property_changed.emit(self, "message_dismissed", previous, message_dismissed)
