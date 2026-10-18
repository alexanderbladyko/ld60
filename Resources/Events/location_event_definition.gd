class_name LocationEventDefinition
extends Resource

@export var event_id: StringName = &""
@export var location: Enums.LocationType = Enums.LocationType.CASTLE
@export_multiline var message: String = ""

@export_range(0.0, 1000.0) var weight: float = 1.0
@export_range(0.0, 600.0) var cooldown_seconds: float = 30.0
@export_range(0.0, 100.0) var effect_duration: float = 30.0
@export var effect: Dictionary[Enums.ResourceType, float] = {}
@export_range(0.0, 100.0) var effect_period: float = 1

@export var options: Dictionary[Enums.LocationType, LocationEventOption] = {}
