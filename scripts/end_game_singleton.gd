extends Node

var books_collected = 0
var deaths = 0

var did_finish = false

var current_skin = Node.new()

func reset_values():
	books_collected = 0
	deaths = 0
	did_finish = false
	current_skin = Node.new()
