class_name C_Location
extends Component

@export var location: Enums.LocationType = Enums.LocationType.CASTLE:
	set(new_value):
		if location == new_value:
			return
		var previous := location
		location = new_value
		property_changed.emit(self, "location", previous, location)
