extends StaticBody3D

func select_image():
	GuiManager.show_cursor()
	$FileDialog.show()

func _on_file_dialog_file_selected(path: String) -> void:
	var image = Image.load_from_file(path)
	
	image.resize(image.get_size().x / 4, image.get_size().y / 4)
	
	for x in image.get_size().x:
		for y in image.get_size().y:
			var color = image.get_pixel(x,y)
			var gray = color.r * 0.299 + color.g * 0.587 + color.b * 0.114
			var grayscale_color = Color(gray, gray, gray)
			
			image.set_pixel(x,y,grayscale_color)
	
	set_image_texture.rpc(image.get_width(),image.get_height(),image.has_mipmaps(),image.get_format(),image.get_data())
	GuiManager.hide_cursor()

@rpc("any_peer","call_local")
func set_image_texture(width,height,use_mipmap,format,data):
	var image = Image.create_from_data(width,height,use_mipmap,format,data)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(image)
	
	$Image.material_override = mat
