extends Node

var saved_tips : Dictionary = {}
var tips_queue = []
var is_showing_tip = false

signal tip_created(text: String, duration: float)

func _ready():
	load_tips()

@rpc("authority", "call_local")
func show_tip(text: String, duration: float = 7):
	tips_queue.push_back({"text": text, "duration": duration})
	process_queue()

@rpc("authority", "call_local")
func show_tip_once(id: String, text: String, duration: float = 7):
	if !saved_tips.has(id):
		saved_tips[id] = text
		tips_queue.push_back({"text": text, "duration": duration})
		process_queue()
		save_tips()

func process_queue():
	if !is_showing_tip and !tips_queue.is_empty():
		is_showing_tip = true
		var tip = tips_queue.pop_front()
		tip_created.emit(tip["text"], tip["duration"])
		print_rich("Showing tip: ", tip["text"])
		await get_tree().create_timer(tip["duration"]).timeout
		is_showing_tip = false
		process_queue()

func save_tips():
	var file = FileAccess.open("user://tooltips.save", FileAccess.WRITE)
	file.store_var(saved_tips)
	file.close()

func load_tips():
	var file = FileAccess.open("user://tooltips.save", FileAccess.READ)
	
	if file:
		saved_tips = file.get_var()
		file.close()
		print("Loaded saved tips")
