extends Node

var ping_start_time = 0
var current_ping = 0

func _ready() -> void:
	if !multiplayer.is_server():
		request_ping()

func request_ping():
	ping_start_time = Time.get_ticks_msec()
	ping_request.rpc_id(1, multiplayer.get_unique_id())

@rpc("any_peer", "call_remote", "reliable")
func ping_request(id):
	# Server receives ping request and sends response
	ping_response.rpc_id(id)

@rpc("authority", "call_remote", "reliable")
func ping_response():
	# Client receives ping response and calculates ping
	var ping = Time.get_ticks_msec() - ping_start_time
	current_ping = ping
	
	print("Current ping: ", ping, " ms, node count:", str(get_tree().get_node_count()))
	ping_start_time = 0  # Reset for next ping request

	# Wait a bit before next ping request
	await Game.sleep(1)
	request_ping()
