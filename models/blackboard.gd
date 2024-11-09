extends StaticBody3D

var drawing = false
var last_position = Vector2.ZERO

@onready var canvas = $CanvasLayer/Panel/TextureRect
@onready var gui: CanvasLayer = $CanvasLayer

func open_ui():
	gui.show()
	GuiManager.show_cursor()

func _ready():
	clear_drawing()

func clear_drawing():
	var image = Image.create(canvas.size.x, canvas.size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLACK)
	canvas.texture = ImageTexture.create_from_image(image)
	last_position = Vector2.ZERO

func _input(event):
	if not gui.visible:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			drawing = event.pressed
			if drawing:
				last_position = get_canvas_position(event.position)
				draw_point(last_position) # Draw initial point
	
	elif event is InputEventMouseMotion and drawing:
		var current_position = get_canvas_position(event.position)
		if current_position != last_position:
			draw_line(last_position, current_position)
			last_position = current_position
	
	if event is InputEventKey:
		if event.as_text_keycode() == "Space" and event.pressed:
			_on_close_pressed()

func get_canvas_position(mouse_pos: Vector2) -> Vector2:
	# Get position relative to canvas
	var pos = mouse_pos - canvas.global_position
	# Clamp to canvas bounds
	pos.x = clamp(pos.x, 0, canvas.size.x)
	pos.y = clamp(pos.y, 0, canvas.size.y)
	return pos

func draw_point(pos: Vector2):
	var image = canvas.texture.get_image()
	
	for ox in range(-1, 2):
		for oy in range(-1, 2):
			var px = int(pos.x + ox)
			var py = int(pos.y + oy)
			if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
				image.set_pixel(px, py, Color.WHITE)
	
	canvas.texture = ImageTexture.create_from_image(image)

func draw_line(from: Vector2, to: Vector2):
	var image = canvas.texture.get_image()
	
	# Calculate direction and distance
	var direction = (to - from).normalized()
	var distance = from.distance_to(to)
	
	# Draw points along the line with small steps
	var step = 1.0  # 1 pixel step
	var current_distance = 0.0
	
	while current_distance < distance:
		var point = from + direction * current_distance
		
		# Draw a 3x3 point
		for ox in range(-1, 2):
			for oy in range(-1, 2):
				var px = int(point.x + ox)
				var py = int(point.y + oy)
				if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
					image.set_pixel(px, py, Color.WHITE)
		
		current_distance += step
		# Add a tiny delay every few pixels
		if int(current_distance) % 10 == 0:
			await get_tree().create_timer(0.0001).timeout
	
	canvas.texture = ImageTexture.create_from_image(image)

func get_drawing() -> Image:
	return canvas.texture.get_image()

@rpc("any_peer", "call_local")
func set_image_texture(width, height, use_mipmaps, format, data):
	var image = Image.create_from_data(width, height, use_mipmaps, format, data)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(image)
	
	$Image.material_override = mat

func _on_close_pressed() -> void:
	gui.hide()
	var drawing := get_drawing()
	
	set_image_texture.rpc(
		drawing.get_width(),
		drawing.get_height(),
		drawing.has_mipmaps(),
		drawing.get_format(),
		drawing.get_data()
	)
	print_rich("[color=orange]Sent out the drawing")
	clear_drawing()
	GuiManager.hide_cursor()
