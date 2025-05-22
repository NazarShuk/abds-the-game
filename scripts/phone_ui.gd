extends CanvasLayer

@export var player : Player
var can_hitman = true

func _process(_delta: float) -> void:
	$hitman_app.disabled = !can_hitman

func _on_hitman_app_pressed() -> void:
	$hitman_app.hide()
	$hitman.show()
	
	for child in $hitman/list.get_children():
		child.queue_free()
	
	var hit_list = []
	hit_list += get_tree().get_nodes_in_group("teacher")
	hit_list += get_tree().get_nodes_in_group("player")
	
	for hit_guy : Node3D in hit_list:
		var button = Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		button.text = hit_guy.name
		if hit_guy is Player:
			button.text = hit_guy.steam_name
		
		button.pressed.connect(func ():
			if !can_hitman: return
			eliminate.rpc_id(1, hit_guy.get_path(), int(player.name))
			
			$hitman_app.show()
			$hitman.hide()
			can_hitman = false
			$hitman/Timer.start()
		)
		
		$hitman/list.add_child(button)
	

@rpc("any_peer", "call_local")
func eliminate(node_path : String, eliminator : int):
	if !multiplayer.is_server(): return
	
	var pl = Game.players.get(eliminator)
	if !pl: return
	
	var node = get_node_or_null(node_path)
	if !node: return
	
	if node is Teacher:
		node.add_speed_multiplier(-node.speed_multiplier, 10)
		Game.info_text(pl.username + " eliminated " + node.name)
		play_boom.rpc($hitman/AudioStreamPlayer.get_path())
	elif node is Player:
		node.lobotomy.rpc_id(int(node.name))
		Game.info_text(pl.username + " lobotomized " + node.steam_name)
	
@rpc("any_peer", "call_local")
func play_boom(path: String):
	if get_node_or_null(path):
		get_node(path).play()


func _on_hitman_timer_timeout() -> void:
	can_hitman = true
