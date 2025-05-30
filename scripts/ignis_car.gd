extends VehicleBody3D

@export var max_steer = 0.8
@export var engine_power = 1000

@export var driver = -1

var player_in_car = false

var d = 0

func _process(delta: float) -> void:
	d = delta
	if multiplayer.has_multiplayer_peer() and multiplayer.get_unique_id() == driver:
		control_car.rpc(multiplayer.get_unique_id(), Input.get_axis("right","left"), Input.get_axis("back","forward") * engine_power)
	
	var local_player = Game.get_player_by_id(multiplayer.get_unique_id())
	
	if !local_player: return
	if player_in_car:
		local_player.global_position = $PlayerTarget.global_position
		local_player.is_in_car = true
		local_player.get_node("CollisionShape3D").disabled = true
		
		if Input.is_action_just_pressed("jump"):
			leave_car.rpc(multiplayer.get_unique_id())
			# Don't set these here - let the RPC handle it
			# local_player.get_node("CollisionShape3D").disabled = false
			# local_player.is_in_car = false
	
	$CanvasLayer.visible = player_in_car
	
@rpc("any_peer","call_local")
func control_car(driver_id, steer, force):
	if !multiplayer.has_multiplayer_peer(): return
	
	if multiplayer.is_server() and driver_id == driver:
		steering = move_toward(steering,steer * max_steer, d * 2.5)
		engine_force = force

@rpc("any_peer","call_local")
func enter_car(driver_id):
	if !multiplayer.has_multiplayer_peer(): return
	
	if multiplayer.is_server():
		print(driver_id, " entered car")
		if driver == -1:
			driver = driver_id
		client_car.rpc_id(driver_id,true)

@rpc("any_peer","call_local")
func leave_car(driver_id):
	if !multiplayer.has_multiplayer_peer(): return
	
	if multiplayer.is_server():
		if driver != -1:
			driver = -1
		client_car.rpc_id(driver_id,false)

@rpc("any_peer","call_local")
func client_car(do_enter):
	player_in_car = do_enter
	
	# Handle player state changes here instead
	var local_player = Game.get_player_by_id(multiplayer.get_unique_id())
	if local_player:
		if not do_enter:  # Player is leaving the car
			local_player.get_node("CollisionShape3D").disabled = false
			local_player.is_in_car = false

@rpc("any_peer","call_local")
func push_item(push_direction,push_force):
	if multiplayer.is_server():
		apply_central_impulse(-push_direction * push_force)
