extends AudioStreamPlayer

@export var streams : Array[SubtitleStream]
@onready var timer = $Timer

signal playback_finished

func play_streams():
	for st in streams:
		stream = st.stream
		play()
		timer.start(st.stream.get_length())
		GuiManager.show_subtitle(st.txt,st.stream)
		await timer.timeout
	
	playback_finished.emit()
