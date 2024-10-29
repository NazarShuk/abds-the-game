extends "res://scripts/teacher.gd"

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var unstucker = $Unstucker

@export var absent = false
@export var appeased = false
@export var baja_blasted = false
var p_timeout = 0
var baja_timer = 0
var power_fix_progress = 0

func _ready():
	super._ready()
	
	Game.on_game_started.connect(_game_started)
	Game.on_book_collected.connect(_on_book_collected)
	Game.on_pre_game_started.connect(_on_pregame_started)
	absent = false
	appeased = false
	baja_blasted = false

func _on_pregame_started():
	if !Game.game_params.get_param("ms_leahy"):
		queue_free()
	
	if !Game.game_params.get_param("absences"):
		$absences.stop()


func _game_started():
	$AudioStreamPlayer3D.play()
	show()

func _on_book_collected(amount):
	if Game.collected_books == 1 and not Game.game_started:
		show()
		$grrrrrr.play()
	
	if multiplayer.is_server():
		var players_in_lobby = Game.players.keys().size()
		if players_in_lobby > 1:
			DEFAULT_SPEED += (0.5 * (players_in_lobby / 2.0)) * amount
		else:
			DEFAULT_SPEED += 0.5 * amount
	

func _physics_process(delta):
	super._physics_process(delta)
	if multiplayer.is_server():
		
		unstucker_constraints()
		
		ai(delta)
		

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
							target_player = closest_player
							
						else:
							target_player = null
							p_timeout += delta
							if p_timeout < 5:
								update_target_location(global_position)
							else:
								var mr_azzu = Game.get_closest_node_in_group(global_position,"mr_azzu")
								if mr_azzu:
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

func _on_pitch_timer_timeout():
	$AudioStreamPlayer3D.pitch_scale = randf_range(0.75,1.25)

func _on_absences_timeout():
	if !multiplayer.is_server() : return
	if !Game.game_started : return
	if Game.powered_off: return
	if GlobalVars.is_bossfight: return
	
	if randi_range(0, 20) == 1: 
		absent = true
		Game.info_text("Ms.Leahy is gone???")
		GuiManager.show_tip_once.rpc("absences","[color=green]Absences[/color]\n\"Sometimes\", Ms.Leahy is absent. She is gone!!!!! Have fun, go nuts!")
		hide()
		$AudioStreamPlayer3D.volume_db = -80
	else:
		if absent == true:
			absent = false
			Game.info_text("Ms.Leahy is here nvm")
			show()
			$AudioStreamPlayer3D.volume_db = 0

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

@rpc("any_peer","call_local")
func boost_leahy(pl):
	if multiplayer.is_server():
		speed_multiplier += 0.5
		Game.add_book_boost.rpc(0.5)
		Game.info_text(pl + " gave Ms.Leahy Redbull...")
