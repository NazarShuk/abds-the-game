extends AudioStreamPlayer

var pitch_target = 1.0


func _ready():
	Game.on_power_changed.connect(_power_changed)

func _power_changed(power_on):
	if power_on:
		play()
	else:
		stop()

func _process(delta):
	
	pitch_scale = lerp(pitch_scale,pitch_target,0.05)
	
	if Allsingleton.is_bossfight == false:
		if Game.collected_books == Game.books_to_collect - 1:
			pitch_target += 0.5
		
		var evil_leahy = get_tree().get_first_node_in_group("evil_leahy")
		
