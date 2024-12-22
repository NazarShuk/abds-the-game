extends ProgressBar

@export var darel : EvilDarel

@export var bossfight : Bossfight


func _process(delta: float) -> void:
	if !bossfight.do_bossfight: return
	if !darel:
		queue_free()
		return
	
	visible = bossfight.do_bossfight and darel
	
	value = lerp(value, float(darel.health), delta)
