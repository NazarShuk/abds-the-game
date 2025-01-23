extends Label


func _ready():
	GuiManager.on_subtitle.connect(_on_subtitle)
	text = ""
	

func _on_subtitle(txt, duration):
	
	text = txt
	show()
	
	var timer := Timer.new()
	timer.one_shot = true
	add_child(timer)
	
	timer.start(duration - 0.1)
	await timer.timeout
	timer.queue_free()
	
	text = ""
	hide()
