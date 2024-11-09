extends VehicleBody3D

@export var max_steer = 0.8
@export var engine_power = 1000

@export var driver = -1

func _process(delta: float) -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.get_unique_id() == driver:
		
		control_car.rpc(multiplayer.get_unique_id(), move_toward(steering,Input.get_axis("right","left") * max_steer, delta * 2.5), Input.get_axis("back","forward") * engine_power)

@rpc("any_peer","call_local")
func control_car(driver_id, steer, force):
	if multiplayer.is_server() and driver_id == driver:
		steering = steer
		engine_force = force
