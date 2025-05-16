extends StaticBody3D

var game : Node3D
var fly_up = false

func _ready() -> void:
	game = get_tree().get_first_node_in_group("game")

func _process(_delta: float) -> void:
	var player = Game.get_closest_node_in_group(global_position, "player")
	if player:
		look_at(player.global_position)
		global_rotation_degrees.x = 0
	
	if fly_up:
		global_position.y += 0.1

func _on_area_3d_area_entered(area: Area3D) -> void:
	if !multiplayer.is_server(): return
	
	if area.is_in_group("player_area"):
		if game.can_escape:
			game.leahy_time_mode.rpc()
			fly_up = true
