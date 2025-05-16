extends Label

@export var timer : Timer

func _process(_delta: float) -> void:
	text = format_time(timer.time_left)

func format_time(seconds: float) -> String:
	# Calculate minutes
	var minutes = floor(seconds / 60)
	
	# Calculate remaining seconds
	var remaining_seconds = seconds - (minutes * 60)
	
	# Calculate whole seconds and milliseconds
	var whole_seconds = floor(remaining_seconds)
	
	# Format the string
	return "%02d:%02d" % [minutes, whole_seconds]
