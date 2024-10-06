extends Node

signal on_subtitle(text, duration)

func show_subtitle(text, stream):
	on_subtitle.emit(text,stream.get_length())
