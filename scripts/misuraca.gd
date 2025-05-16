extends Teacher

@onready var unstucker = $Unstucker

@export var is_angry = false

var init_pos : Vector3

var broken_machines = []

func _ready():
	super._ready()
	init_pos = global_position
	Game.on_pre_game_started.connect(_on_pregame_started)

func _on_pregame_started():
	if !Game.game_params.get_param("mr_misuraca"):
		queue_free()

func _physics_process(_delta):
	super._physics_process(_delta)
	
	var cloroxes = get_tree().get_nodes_in_group("clorox_wipes")
	
	for clorox in cloroxes:
		var distance = global_position.distance_to(clorox.global_position)
		
		if distance < 5:
			if multiplayer.is_server():
				target_player = Game.get_player_by_id(clorox.launcher)
				Game.info_text("Mr.Misuraca is angry")
	
	if multiplayer.is_server():
		unstucker.do_penalties = ((target_player != null) and broken_machines.size() > 0)
		
		go_back()
		fix_vending_machines()

func go_back():
	if target_player:
		update_target_location(target_player.global_position)
		is_angry = true
	else:
		update_target_location(init_pos)
		is_angry = false


func fix_vending_machines():
	if !multiplayer.is_server(): return
	var vending_machines = get_tree().get_nodes_in_group("vending_machines")
	
	broken_machines = []
	
	for machine in vending_machines:
		if machine.uses_left <= 0:
			broken_machines.append(machine)
			var dst = global_position.distance_to(machine.global_position)
			if dst < 2:
				machine.uses_left = machine.MAX_USES
	
	if !target_player and broken_machines.size() > 0:
		update_target_location(broken_machines[0].global_position)

func _on_misuraca_area_entered(area):
	if area.is_in_group("player_area"):
		if target_player:
			if area.get_parent().name == target_player.name:
				target_player = null
