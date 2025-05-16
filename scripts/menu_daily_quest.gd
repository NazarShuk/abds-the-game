extends Control

@onready var quest_text: Label = $quest_text
@onready var progress: ProgressBar = $progress
@onready var expires: Label = $expires

func _ready() -> void:
	if Time.get_unix_time_from_system() - Achievements.daily_quest.generated_on > 12 * 60 * 60 * 1000:
		Achievements.generate_daily_quest()
		

func _process(delta: float) -> void:
	$expires.text = "Expires in %s minutes" % [ceil((Achievements.daily_quest.generated_on + 12 * 60 * 60 * 1000) - Time.get_unix_time_from_system())]
	$progress.value = Achievements.quest_progress / Achievements.daily_quest["value"]
