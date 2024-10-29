extends Node3D

@onready var w1 = $w1
@onready var w2 = $w2
@onready var w3 = $w3
@onready var http_request = $HTTPRequest

func _ready():
	prepare_leaderboard()

func prepare_leaderboard():
	http_request.request(GlobalVars.api_url,["User-Agent: insomnia/9.3.2","Accept: /*/","Content-Length: 0"],HTTPClient.METHOD_GET)

func _on_http_request_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if result == 0:
		var leaderboard = JSON.parse_string(body.get_string_from_utf8())
		if !leaderboard: return
		
		var keys : Array = leaderboard.keys()
		keys.reverse()
		
		for key in range(keys.size()):
			if key == 0:
				w1.show()
				
				var mesh : TextMesh = w1.mesh
				mesh.text = keys[key] + "\n" + str(leaderboard[keys[key]]) + " books"
			if key == 1:
				w2.show()
				
				var mesh : TextMesh = w2.mesh
				mesh.text = keys[key] + "\n" + str(leaderboard[keys[key]]) + " books"
			if key == 2:
				w3.show()
				var mesh : TextMesh = w3.mesh
				mesh.text = keys[key] + "\n" + str(leaderboard[keys[key]]) + " books"
	else:
		hide()
