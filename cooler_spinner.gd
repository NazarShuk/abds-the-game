extends Spinner

var direction = 1

func _process(delta: float) -> void:
	super(delta)
	
	spin_fill_percent += 0.01 * direction
	
	if spin_fill_percent >= 1.0:
		direction = -1
	
	if spin_fill_percent <= 0.0:
		direction = 1
