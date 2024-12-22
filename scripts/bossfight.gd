extends Node3D
class_name Bossfight

const SCHOOL = preload("res://school.tscn")
@onready var music: AudioStreamPlayer = $music

var school : Node3D
@onready var sub: SubViewportContainer = $CanvasLayer/SubViewportContainer

var do_bossfight = false

func _ready() -> void:
	school = SCHOOL.instantiate()
	add_child(school)
	school.global_position = Vector3(24.563,0,-137.18)
	school.global_rotation_degrees.y = 180
	school.hide()
	
	intro_sequence()
	$intro/AnimationPlayer.play("intro")
	
	await get_tree().create_timer(14.2, false).timeout
	$Cloroxes.show()
	$CanvasLayer/TextureRect.show()
	await get_tree().create_timer(28.5 - 14.2, false).timeout
	do_bossfight = true
	

func intro_sequence():
	music.play()
	await Game.sleep(14.2)
	
	var all_nodes_in_school = get_all_children(school)
	
	# Filter nodes before the main loop to improve performance
	var visible_nodes = all_nodes_in_school.filter(
		func(node): return node.has_method("set_visible") and not node is CanvasLayer and node.visible
	)
	
	# Hide all nodes first
	for node in visible_nodes:
		node.visible = false
	school.show()
	
	var start_time = Time.get_ticks_msec()
	var total_time_ms = ((28.5 - 14.2) - 1) * 1000.0  # Convert to milliseconds
	var time_per_node_ms = total_time_ms / visible_nodes.size()
	
	# Show nodes using precise timing
	for i in visible_nodes.size():
		var node = visible_nodes[i]
		
		# Calculate exact time this node should appear
		var target_time = start_time + (i * time_per_node_ms)
		
		# Wait until exactly the right moment
		while Time.get_ticks_msec() < target_time:
			await get_tree().process_frame
		
		node.visible = true
	
	# Ensure we've used exactly the right amount of time
	while Time.get_ticks_msec() < start_time + total_time_ms:
		await get_tree().process_frame
	
	

func get_all_children(node: Node) -> Array:
	var children = []
	
	# Get immediate children
	for child in node.get_children():
		# Add the child itself
		children.append(child)
		# Recursively get children of this child
		children.append_array(get_all_children(child))
	
	return children

func transition_to_phase_2():
	school.queue_free()
	school = null
	
	
	$Pillar.global_position = get_tree().get_first_node_in_group("player").global_position
	$Pillar.global_position.y -= 80
	$Pillar.show()
	$music.set("parameters/switch_to_clip", "phase2_intro")
	
	await get_tree().create_timer(30.0, false).timeout
	$Pillar/CPUParticles3D.emitting = true
	await get_tree().create_timer(32.05 - 30.0, false).timeout
	
