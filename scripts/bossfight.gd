extends Node3D
class_name Bossfight

const SCHOOL = preload("res://school.tscn")
@onready var music: AudioStreamPlayer = $music

var school : Node3D
@onready var sub: SubViewportContainer = $CanvasLayer/SubViewportContainer

var do_bossfight = false

const PART2 = preload("res://bossfight_part2.tscn")
@onready var evil_darel: EvilDarel = $EvilDarel

var multiplier = 1

var phase_2 = false

func _ready() -> void:
	
	if OS.has_feature("debug"): multiplier = 0
	
	school = SCHOOL.instantiate()
	add_child(school)
	school.global_position = Vector3(24.563,0,-137.18)
	school.global_rotation_degrees.y = 180
	school.hide()
	
	intro_sequence()
	if !OS.has_feature("debug"):
		$intro/AnimationPlayer.play("intro")
	else:
		$intro/AnimationPlayer.play("intro", -1, 1000)
	
	await get_tree().create_timer(14.2 * multiplier, false).timeout
	$Cloroxes.show()
	$CanvasLayer/TextureRect.show()
	await get_tree().create_timer((28.5 - 14.2) * multiplier, false).timeout
	do_bossfight = true

func _process(delta: float) -> void:
	$"azzu cutscene/Camera3D".global_position = $BossfightPlayer/Head.global_position
	if !$"azzu cutscene/AnimationPlayer".is_playing():
		$"azzu cutscene/Camera3D".global_rotation = $BossfightPlayer/Head.global_rotation

func intro_sequence():
	music.play()
	await Game.sleep(14.2 * multiplier)
	
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
	var total_time_ms = ((28.5 - 14.2) - 1) * 1000.0 * multiplier  # Convert to milliseconds
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
	phase_2 = true
	$music.stop()

	evil_darel.do_chase = false
	$"azzu cutscene/AnimationPlayer".play("cutscene")
	
	await get_tree().create_timer(1, false).timeout
	$CanvasLayer.hide()
	await get_tree().create_timer(9, false).timeout
	$"clorox gun".show()
	$music.play()
	$music.set("parameters/switch_to_clip","phase2_intro")
	
	evil_darel.health = 50
	evil_darel.speed = 10
	
	await get_tree().create_timer(2, false).timeout
	$"clorox gun/AnimationPlayer".play("look_at_it")
	$CanvasLayer.show()
	
	await get_tree().create_timer(10.71 - 2, false).timeout
	evil_darel.do_chase = true
