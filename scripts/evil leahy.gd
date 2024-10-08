extends CharacterBody3D

@onready var nav_agent : NavigationAgent3D = $NavigationAgent3D
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var unstucker = $Unstucker

var SPEED = 6.0
var speed = SPEED

var overwrite_speed = false

const push_force = 1.0

var distance_to_target = -1

@export var absent = false
@export var appeased = false
@export var baja_blasted = false
var p_timeout = 0
var baja_timer = 0
var power_fix_progress = 0

var current_player_target = null

func _physics_process(delta):
	
	if multiplayer.is_server():
		if !overwrite_speed:
			speed = SPEED
		
		unstucker_constraints()
		
		ai(delta)
		
		navigation()
		
		stick_to_clorox()
		
		push_items()
	
	move_and_slide()

func unstucker_constraints():
	unstucker.do_penalties = (absent == false && appeased == false && baja_blasted == false)

func ai(delta):
	if Game.game_started and multiplayer.is_server() and !absent:
			if !appeased:
				if !Game.powered_off:
					if !baja_blasted:
						var closest = null
						var closest_distance = INF
						var closest_player = null
						
						for p in Game.players.keys():
							if !Game.players[p].is_dead:
								var player = Game.get_player_by_id(p)
								var distance = global_position.distance_to(player.global_position)
							
								if distance < closest_distance:
									closest = player.global_position
									closest_distance = distance
									closest_player = player
						
						if closest:
							update_target_location(closest)
							p_timeout = 0
							current_player_target = closest_player
						else:
							current_player_target = null
							p_timeout += delta
							if p_timeout < 5:
								update_target_location(global_position)
							else:
								var mr_azzu = Game.get_closest_node_in_group(global_position,"mr_azzu")
								update_target_location(mr_azzu.global_position)
					else:
						# baja blast
						var bathrooms = get_tree().get_nodes_in_group("bathroom_spawn")
						
						var clst_dist = INF
						var clst_bathroom = null
						
						for bathroom : Node3D in bathrooms:
							var dst = global_position.distance_to(bathroom.global_position)
							if dst < clst_dist:
								clst_dist = dst
								clst_bathroom = bathroom
						
						update_target_location(clst_bathroom.global_position)
						
						if clst_dist < 5 && baja_timer <= 15:
							baja_timer += delta
							print(baja_timer)
						
						if baja_timer >= 15:
							baja_blasted = false
							baja_timer = 0
						
				else:
					var breaker = get_tree().get_first_node_in_group("breaker")
					
					update_target_location(breaker.global_position)
					var breaker_dst = global_position.distance_to(breaker.global_position)
					if breaker_dst < 2:
						power_fix_progress += delta
						if power_fix_progress >= 3:
							breaker.toggle_power.rpc(true,false)
							power_fix_progress = 0
						
			else:
				update_target_location(global_position)

func navigation():
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	
	var new_velocity = (next_location - current_location).normalized() * speed
	
	distance_to_target = 0
	
	var path = nav_agent.get_current_navigation_path()
	
	for point in range(path.size()):
		if path[point - 1]:
			distance_to_target += path[point - 1].distance_to(path[point])
		else:
			distance_to_target += global_position.distance_to(path[point])
	
	distance_to_target = distance_to_target / 2
	
	velocity = new_velocity
	if global_transform.origin != next_location:
		if global_position.distance_to(next_location) > 1.5:
			look_at(next_location)
		rotation_degrees.x = 0
		rotation_degrees.z = 0

func push_items():
	for index in range(get_slide_collision_count()):
		var collision = get_slide_collision(index)
		var collider = collision.get_collider()
		
		# If the collider is a RigidBody
		if collider is RigidBody3D:
			# Calculate the push direction
			var push_direction = collision.get_normal()
			
			# Apply the force to the RigidBody
			collider.push_item.rpc(push_direction,push_force)

func stick_to_clorox():
	var cloroxes = get_tree().get_nodes_in_group("clorox_wipes")
	for clorox in cloroxes:
		if global_position.distance_to(clorox.global_position) < 1:
			velocity = Vector3()

func update_target_location(target_location):
	if typeof(target_location) == TYPE_VECTOR3:
		nav_agent.target_position = target_location

func _on_evil_leahy_area_entered(area):
	if area.name == "puddle":
		if !area.get_parent().can_slowdown: return
		
		overwrite_speed = true
		speed = SPEED / 2
		$CPUParticles3D.show()
		await Game.sleep(5)
		overwrite_speed = false
		$CPUParticles3D.hide()

func _on_pitch_timer_timeout():
	$AudioStreamPlayer3D.pitch_scale = randf_range(0.5,1.5)


func _on_absences_timeout():
	if !multiplayer.is_server() : return
	if !Game.game_started : return
	if Game.powered_off: return
	if Allsingleton.is_bossfight: return
	
	if randi_range(0, 20) == 1: 
		absent = true
		Game.info_text("Ms.Leahy is gone???")
		GuiManager.show_tip_once.rpc("absences","[color=green]Absences[/color]\n\"Sometimes\", Ms.Leahy is absent. She is gone!!!!! Have fun, go nuts!")
		hide()
	else:
		if absent == true:
			absent = false
			Game.info_text("Ms.Leahy is here nvm")
			show()

func _on_appeasement_timeout():
	if !multiplayer.is_server(): return
	
	appeased = false

@rpc("any_peer","call_local")
func appease(who, seconds):
	if !multiplayer.is_server(): return
	
	appeased = true
	$appeasement.start(seconds)
	Game.info_text(who + " appeased Ms.Leahy for " + str(seconds) + " seconds")

@rpc("any_peer","call_local")
func baja_blast_her(steam_name):
	if !multiplayer.is_server(): return
	
	baja_blasted = true
	Game.info_text(steam_name + " gave Ms.Leahy baja blast")
