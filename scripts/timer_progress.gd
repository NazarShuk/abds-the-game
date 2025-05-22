extends ProgressBar

@export var timer : Timer
@export var max_val : float

func _ready() -> void:
	max_value = max_val

func _process(_delta: float) -> void:
	value = 300 - timer.time_left
