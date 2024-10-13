extends Node

const api_url = "https://script.google.com/macros/s/AKfycbwwbWjvbwCQxZcnXEikI96x1sYPKr6lxIpzs0IFw4M0WolIjuSBZbG36cQVDBnQPDSK/exec"

func set_values():
	if OS.has_feature("debug"): return
	
	var http = HTTPRequest.new()
	http.timeout = 5
	add_child(http)
	
	var books = Achievements.books_collected
	
	http.request_completed.connect(_on_post_request_completed)
	http.request(api_url + "?username=" + SteamManager.steam_name + "&books=" + str(books),["User-Agent: insomnia/9.3.2","Accept: /*/","Content-Length: 0"],HTTPClient.METHOD_POST)

func _on_post_request_completed(result: int, _response_code: int, _headers: PackedStringArray, _body: PackedByteArray):
	if result == 0:
		print("set books cool")
	else:
		print("error", result)
