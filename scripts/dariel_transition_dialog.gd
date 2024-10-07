extends AudioStreamPlayer

@export var streams : Array[SubtitleStream]
@onready var timer = $Timer

signal playback_finished

func play_streams():
	for str in streams:
		stream = str.stream
		play()
		timer.start(str.stream.get_length())
		GuiManager.show_subtitle(str.txt,str.stream)
		await timer.timeout
	
	playback_finished.emit()
