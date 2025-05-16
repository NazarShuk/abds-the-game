extends CharacterBody3D
class_name Teacher

const WATER_PARTICLES = preload("res://scenes/water_particles.tscn")

const push_force = 1.0

@export var nav_agent : NavigationAgent3D
@export var area_3d : Area3D

@export var DEFAULT_SPEED = 5.0
@export var speed = 5.0
var speed_multiplier = 1

var target_player = null
@export var target_player_name = ""

func _ready() -> void:
	if multiplayer.is_server():
		area_3d.area_entered.connect(_on_area_entered)
		area_3d.area_exited.connect(_on_area_exited)
	
	add_to_group("teacher")

func _on_area_entered(area : Area3D):
	if area.name == "puddle":
		speed_multiplier -= 0.5
		var water = WATER_PARTICLES.instantiate()
		add_child(water)
		
		await Game.sleep(5)
		speed_multiplier += 0.5
		
		water.queue_free()
	elif area.name == "Door":
		area.get_parent().set_open.rpc(true)
		play_sound("res://sounds/door_open.mp3")

func _on_area_exited(area : Area3D):
	if area.name == "Door":
		area.get_parent().set_open.rpc(false)
		play_sound("res://sounds/door_close.mp3")

func _physics_process(_delta: float) -> void:
	if multiplayer.is_server():
		
		speed = DEFAULT_SPEED * speed_multiplier
		
		target_players()
		
		item_collision()
		
		stick_to_clorox()
		
		navigation()
		
		phone_suspension()
		
		move_and_slide()

func phone_suspension():
	for player : Player in get_tree().get_nodes_in_group("player"):
		if can_see(self, player):
			if player.phone_open and not player.pending_suspension:
				player.pend_suspension.rpc_id(int(player.name))

func add_speed_multiplier(multiplier : float, duration : float):
	speed_multiplier += multiplier
	await get_tree().create_timer(duration, false).timeout
	speed_multiplier -= multiplier

func target_players():
	if target_player:
		if "steam_name" in target_player:
			target_player_name = target_player.steam_name

func update_target_location(target_location):
	if typeof(target_location) == TYPE_VECTOR3:
		nav_agent.target_position = target_location

func navigation():
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	
	var new_velocity = (next_location - current_location).normalized() * speed
	
	
	velocity = new_velocity
	if global_transform.origin != next_location:
		if global_position.distance_to(next_location) > 1.5:
			look_at(next_location)
		rotation_degrees.x = 0
		rotation_degrees.z = 0

func item_collision():
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
		if global_position.distance_to(clorox.global_position) < 2:
			velocity = Vector3()
			global_position = clorox.global_position - Vector3(0.5,0,0)

func play_sound(stream_path : String,volume_db : float = 0, bus : String = "Dialogs", max_distance : float = 20):
	play_sound_rpc.rpc(stream_path,volume_db,bus,max_distance,global_position)

@rpc("any_peer","call_local")
func play_sound_rpc(stream_path : String,volume_db : float = 0, bus : String = "Dialogs", max_distance : float = 20,pos = Vector3()):
	if !multiplayer.is_server(): return
	
	var a = load("res://scenes/player_sound.tscn").instantiate()
	get_parent().add_child(a,true)
	
	var audio_stream : AudioStream = load(stream_path)
	
	actually_play_sound.rpc(a.get_path(),stream_path,volume_db,bus,max_distance,pos)
	
	await Game.sleep(audio_stream.get_length())
	a.queue_free()

@rpc("any_peer","call_local")
func actually_play_sound(sound_path, stream_path : String,volume_db : float = 0, bus : String = "Dialogs", max_distance : float = 20,pos = Vector3()):
	var sound = get_node_or_null(sound_path)
	if sound:
		sound.stream = load(stream_path)
		sound.bus = bus
		sound.max_distance = max_distance
		sound.volume_db = volume_db
		sound.global_position = pos
		sound.play()

func can_see(observer: Node3D, target: Node3D) -> bool:
	var from     = observer.global_transform.origin
	var to       = target.global_transform.origin
	var space    = observer.get_world_3d().direct_space_state

	# --- set up a ray‐query
	var qr = PhysicsRayQueryParameters3D.new()
	qr.from           = from
	qr.to             = to
	qr.exclude        = [observer]       # don’t hit yourself
	# qr.collision_mask = 0xffffffff     # (optional) limit to certain layers

	# --- do the cast
	var result : Dictionary = space.intersect_ray(qr)
	# result is a Dictionary with keys like "position","normal","collider" if you hit something,
	# or an empty Dictionary if you hit nothing.

	if result.keys().size() == 0:
		# no collider at all between you and the target
		# if your target has no PhysicsBody/CollisionShape, this is still “visible”
		return true
	# otherwise see if the very first thing I hit was my target
	return result["collider"] == target
