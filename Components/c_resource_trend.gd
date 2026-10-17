class_name C_ResourceTrend
extends Component

var source: C_Resource
var last_resource: Enums.ResourceType = Enums.ResourceType.FOOD
var previous_value: float = 0.0
var elapsed: float = 0.0
var samples: Array[Vector2] = []
