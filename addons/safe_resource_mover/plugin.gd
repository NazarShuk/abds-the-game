@tool
extends EditorPlugin

const GUI = preload("res://addons/safe_resource_mover/GUI.tscn")

var gui : SafeResourceMoverGUI

var previous_selected_path = ""

func _enter_tree() -> void:
	gui = GUI.instantiate()
	
	add_control_to_bottom_panel(gui, "Safe Resource Mover")
	
	gui.submit_btn.pressed.connect(func ():
		var containing = check_resource(gui.input.text)
		
		gui.result.text = "Found in %s files:\n" % [containing.size()]
		for contained in containing:
			gui.result.text += "%s\n" % contained
	)


func _process(delta: float) -> void:
	if gui.visible:
		var selectesd_paths = EditorInterface.get_selected_paths()
		if selectesd_paths.size() > 0:
			if selectesd_paths[0] != previous_selected_path:
				
				gui.input.text = selectesd_paths[0]
				gui.submit_btn.pressed.emit()
				
				previous_selected_path = selectesd_paths[0]
		

func _exit_tree() -> void:
	remove_control_from_bottom_panel(gui)
	gui.queue_free()
	

func check_resource(path : String):
	var files = get_all_files()
	
	var contained_files : Array[String] = []
	
	for file_path in files:
		var file = FileAccess.open(file_path, FileAccess.READ)
		var content = file.get_as_text()
		
		if content.contains(path):
			contained_files.append(file_path)
	
	return contained_files
	

func get_all_files(path = "res://", extension = ".gd") -> Array[String]:
	var files : Array[String] = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename != "":
			if dir.current_is_dir():
				if filename != "." and filename != "..":
					files += get_all_files(path.path_join(filename))
			else:
				if filename.ends_with(extension):
					files.append(path.path_join(filename))
			filename = dir.get_next()
		dir.list_dir_end()
	
	return files
