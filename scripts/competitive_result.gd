extends EndCutscene


func _ready() -> void:
	$CanvasLayer/Label.text = "Team %s won!" % [GlobalVars.competitive_team_won]
	
	super._ready()
	
	await get_tree().create_timer(10, false).timeout
	_on_timer_timeout()
