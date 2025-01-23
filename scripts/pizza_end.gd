extends EndCutscene


func _ready() -> void:
	
	$CanvasLayer/Control/AnimatedSprite2D.play(GlobalVars.leahy_time_rank)
	achievement_name = "leahy_time_" + GlobalVars.leahy_time_rank + " rank"
	do_achievement = true
	
	super._ready()
	
