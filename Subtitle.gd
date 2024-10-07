extends Label

var subtitles_queue = {}

func _ready():
	GuiManager.on_subtitle.connect(_on_subtitle)
	text = ""

func _process(delta):
	text = ""
	for txt in subtitles_queue.keys():
		text += txt + "\n"
	
	visible = subtitles_queue.keys().size() > 0
	

func _on_subtitle(txt, duration):
	
	subtitles_queue[txt] = true
	
	var timer := Timer.new()
	timer.one_shot = true
	add_child(timer)
	
	timer.start(duration)
	await timer.timeout
	timer.queue_free()
	
	subtitles_queue.erase(txt)
