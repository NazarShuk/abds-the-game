extends ColorRect
@onready var label = $Label
@onready var animation_player = $AnimationPlayer
@onready var audio = $AudioStreamPlayer

func _ready():
	GuiManager.tip_created.connect(_on_tip)

func _on_tip(text : String, duration : float):
	label.text = text
	animation_player.play("popup")
	$Timer.start(duration)
	audio.play()

func _on_timer_timeout():
	animation_player.play("RESET")
