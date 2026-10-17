class_name C_ResourceView
extends Component

@export var resource: Enums.ResourceType = Enums.ResourceType.FOOD:
	set(new_value):
		if resource == new_value:
			return
		var previous := resource
		resource = new_value
		property_changed.emit(self, "resource", previous, resource)
