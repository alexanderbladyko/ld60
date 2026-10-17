class_name C_Resource
extends Component

@export var value: float = 100:
	set(new_value):
		if value == new_value:
			return
		var previous := value
		value = new_value
		property_changed.emit(self, "value", previous, value)

@export var resource: Enums.ResourceType = Enums.ResourceType.FOOD:
	set(new_value):
		if resource == new_value:
			return
		var previous := resource
		resource = new_value
		property_changed.emit(self, "resource", previous, resource)

@export var cap: float = 100:
	set(new_value):
		if cap == new_value:
			return
		var previous := cap
		cap = new_value
		property_changed.emit(self, "cap", previous, cap)
