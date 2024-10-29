extends AudioStreamPlayer

var pitch_target = 1.0


func _ready():
	Game.on_power_changed.connect(_power_changed)

func _power_changed(power_on):
	if power_on:
		play()
	else:
		stop()

func _process(_delta):
	
	pitch_scale = lerp(pitch_scale,pitch_target,0.05)
	
	if GlobalVars.is_bossfight == false:
		
		
		var final_pitch = 1.0
		
		if Game.collected_books == Game.books_to_collect - 1:
			final_pitch += 0.5
		
		var evil_leahy = get_tree().get_first_node_in_group("evil_leahy")
		if evil_leahy:
			if evil_leahy.absent:
				final_pitch -= 0.5
		
		final_pitch += Game.book_boost
		
		pitch_target = final_pitch
