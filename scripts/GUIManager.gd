extends Node

signal on_subtitle(text, duration)

func show_subtitle(text, stream):
	on_subtitle.emit(text,stream.get_length())
func show_subtitle_for(text,sec):
	on_subtitle.emit(text,sec)

var saved_tips : Dictionary = {}
var tips_queue = []
var is_showing_tip = false

# Cursor management
var _cursor_requests: int = 0
var _force_cursor_visible: bool = false

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
		await Game.sleep(tip["duration"])
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

func show_cursor() -> void:
	_cursor_requests += 1
	_update_cursor_state()

func hide_cursor() -> void:
	_cursor_requests = max(0, _cursor_requests - 1)
	_update_cursor_state()

func force_cursor_state(visible: bool) -> void:
	_force_cursor_visible = visible
	_cursor_requests = 0  # Clear all previous requests
	_update_cursor_state()

func _update_cursor_state() -> void:
	if _force_cursor_visible or _cursor_requests > 0:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func reset_cursor() -> void:
	_cursor_requests = 0
	_force_cursor_visible = false
	_update_cursor_state()

func is_cursor_visible() -> bool:
	return _force_cursor_visible or _cursor_requests > 0
