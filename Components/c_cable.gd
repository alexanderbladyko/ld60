class_name C_Cable
extends Component

enum State { DRAGGING, CONNECTED }

var source: Entity
var target: Entity
var cursor_position: Vector2 = Vector2.ZERO
var state: State = State.DRAGGING

@export var color: Color = Color(0.85, 0.64, 0.29, 1.0)
@export_range(1.0, 20.0) var width: float = 12.0
@export_range(0.0, 150.0) var sag: float = 45.0
