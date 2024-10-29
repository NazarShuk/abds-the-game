extends "res://scripts/teacher.gd"

var SPEED = 15

@export var angered = false

func _ready():
	super._ready()
	Game.on_pre_game_started.connect(_on_pregame_started)

func _on_pregame_started():
	if !Game.game_params.get_param("mr_azzu"):
		queue_free()

func _physics_process(_delta):
	super._physics_process(_delta)
	
	if !multiplayer.is_server(): return
	
	anger_issues()
	
	pick_up_expired_items()
	
	cloroxes_anger()
	

func anger_issues():
	angered = target_player != null
	
	if target_player:
		update_target_location(target_player.global_position)

func pick_up_expired_items():
	if target_player: return
	
	var expired_items = get_tree().get_nodes_in_group("expired_item")
	
	if expired_items.size() > 0:
		var closest_item = null
		var closetst_distance = INF
		
		for item in expired_items:
			var dst = global_position.distance_to(item.global_position) 
			if dst < closetst_distance:
				closetst_distance = dst
				closest_item = item
		
		update_target_location(closest_item.global_position)
		
		if global_position.distance_to(closest_item.global_position) < 1:
			closest_item.queue_free()

func cloroxes_anger():
	var cloroxes = get_tree().get_nodes_in_group("clorox_wipes")
	
	for clorox in cloroxes:
		var distance = global_position.distance_to(clorox.global_position)
		
		if distance < 5:
			if multiplayer.is_server():
				var player = Game.get_player_by_id(clorox.launcher)
				if !player: return
				
				target_player = player
				Game.info_text("Mr.Azzu is angry")
			
			break


func _on_timer_timeout():
	if !multiplayer.is_server(): return
	
	var points = get_tree().get_nodes_in_group("book_spawn")
	update_target_location(points.pick_random().global_position)

func _on_azzu_area_entered(area):
	if area.is_in_group("player_area"):
		if target_player:
			if area.get_parent().name == target_player.name:
				target_player = null
