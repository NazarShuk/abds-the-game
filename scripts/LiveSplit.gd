extends Node

var pipe_path = r"\\.\pipe\LiveSplit"  # Use r for raw string to handle backslashes

var enable_live_split = true

func start_timer():
	send_msg("starttimer")

func start_or_split():
	send_msg("startorsplit")

func split():
	send_msg("split")

func reset():
	send_msg("reset")

func pause():
	send_msg("pause")

func resume():
	send_msg("resume")

@rpc("any_peer","call_local")
func split_for_everyone():
	LiveSplit.start_or_split()

func send_msg(message : String):
	if !enable_live_split: return
	
	print(message)
	var output = []
	OS.execute("cmd.exe", ["/C", "echo " + message + " > " + pipe_path], output, true)
