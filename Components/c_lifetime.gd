class_name C_Lifetime
extends Component

@export var remaining: float = 4.0:
	set(new_value):
		if remaining == new_value:
			return
		var previous := remaining
		remaining = new_value
		property_changed.emit(self, "remaining", previous, remaining)
