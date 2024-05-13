extends CharacterBody3D


var SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var books_collected = 0

var is_running = false
var stamina = 50
var can_run = true
var is_moving = false
var can_move = true

@onready var progress_bar : ProgressBar = $CanvasLayer/Control/ProgressBar

var is_dead = false

@onready var ray = $RayCast3D

var revive_poses = [
 Vector3(0,1.2,-10),
 Vector3(-18,1.2,-24),
 Vector3(-26,1.2,-57),
 Vector3(34,1.2,-47),
 Vector3(8,1.2,-28)
	
]
func _enter_tree():
	set_multiplayer_authority(name.to_int())
	$nametag.text = Steam.getPersonaName()
	
	if is_multiplayer_authority():
		$CanvasLayer.show()
		pick_item(1)

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	

func _physics_process(delta):
	if is_multiplayer_authority():
		#global_rotation_degrees.x = 0
		#global_rotation_degrees.z = 0
		
		$Camera3D.current = true
		# Add the gravity.
		if not is_on_floor() and not is_dead:
			velocity.y -= gravity * delta
			
		$AudioStreamPlayer3D.volume_db = -80
		
		if Input.is_action_just_pressed("sprint"):
			is_running = true
		elif Input.is_action_just_released("sprint"):
			is_running = false
		
		velocity.x = 0
		velocity.z = 0
		
		if get_parent().canPlayersMove:
			if can_move:
				if Input.is_action_pressed("forward"):
					translate(Vector3(0,0,SPEED * -delta))
					$AudioStreamPlayer3D.volume_db = 0
					is_moving = true
				elif Input.is_action_pressed("back"):
					translate(Vector3(0,0,SPEED * delta))
					$AudioStreamPlayer3D.volume_db = 0
					is_moving = true

				if Input.is_action_pressed("left"):
					translate(Vector3(SPEED * -delta,0,0))
					$AudioStreamPlayer3D.volume_db = 0
					is_moving = true

				elif Input.is_action_pressed("right"):
					translate(Vector3(SPEED * delta,0,0))
					$AudioStreamPlayer3D.volume_db = 0
					is_moving = true

				if Input.is_action_just_released("back") or Input.is_action_just_released("forward") or Input.is_action_just_released("left") or Input.is_action_just_released("right"):
					is_moving = false
					
				if Input.is_action_just_pressed("interact"):
					if ray.get_collider():
						print(ray.get_collider().name)
						
						if ray.get_collider().is_in_group("vending_machine"):
							get_parent().use_vending_machine.rpc()
	
		move_and_slide()
		
		progress_bar.value = lerp(progress_bar.value,float(stamina),0.2)

func _input(event):
	if !is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion and get_parent().canPlayersMove:
		if can_move:
			rotate_y(deg_to_rad(event.relative.x * -0.3))


func _on_area_3d_area_entered(area):
	if !is_multiplayer_authority(): return
	if is_dead: return
	
	print(area.name)
	if area.get_parent().is_in_group("Book"):
		print(area.get_parent().get_groups())
		if area.get_parent().get_groups().size() == 2:
			get_parent().on_collect_book.rpc(name.to_int(),area.get_parent().get_groups()[1])
	elif area.get_parent().is_in_group("enemies") and get_parent().game_started == true:
		#velocity.y += 15
		
		$visual_body.global_rotation_degrees.x = 0
		can_move = false
		get_parent().set_played_dead.rpc(name.to_int(),true)
		$"CanvasLayer/Control/Died thing".show()
		$ReviveTimer.start()
		is_dead = true
		AudioServer.set_bus_mute(1,true)
		AudioServer.set_bus_mute(2,true)
		$"CanvasLayer/Control/Died thing/AudioStreamPlayer".play()
		$CollisionShape3D.disabled = true
		
	elif area.name == "azzu":
		velocity.y += 15		


func _on_timer_timeout():
	if !is_multiplayer_authority(): return
	if is_running and is_moving:
		if stamina > 0:
			if can_run:
				stamina -= 1
				SPEED = 10
		else:
			is_running = false
			can_run = false
			$Stamina_timeout.start()
	else:
		SPEED = 5
		if stamina <= 50:
			stamina+= 1
		
	#print(stamina)	


func _on_stamina_timeout_timeout():
	if !is_multiplayer_authority(): return	
	can_run = true


func _on_revive_timer_timeout():

	get_parent().set_played_dead.rpc(name.to_int(),false)
	global_position = revive_poses.pick_random()
	$"CanvasLayer/Control/Died thing".hide()
	AudioServer.set_bus_mute(1,false)
	AudioServer.set_bus_mute(2,false)
	is_dead = false
	$visual_body.global_rotation_degrees.x = 0	
	can_move = true
	$CollisionShape3D.disabled = false

func pick_item(item : int):
	
	for i in $Hand.get_children():
		i.hide()
	
	$Hand.get_child(item).show()

func get_cur_item():
	
	var id
	for i in range(0,$Hand.get_children().size()):
		if $Hand.get_children()[i].visibile == true:
			id = i
			break
			
	return id
