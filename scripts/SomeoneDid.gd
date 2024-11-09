extends Label

var shake = false
var shake_strength = 5
@onready var initial_pos = position

func _ready():
	Game.on_info_text.connect(_on_info_text)

func _process(_delta):
	var clr:Color = get("theme_override_colors/font_color")
	set("theme_override_colors/font_color",clr.lerp(Color(0,0,0,0),0.01))
	
	var outline_color = get("theme_override_colors/font_outline_color")
	set("theme_override_colors/font_outline_color",outline_color.lerp(Color(0,0,0,0),0.01))
	if shake:
		position = initial_pos + Vector2(randf_range(-shake_strength,shake_strength),randf_range(-shake_strength,shake_strength))
	
func _on_info_text(info):
	text = info
	set("theme_override_colors/font_color",Color.BLACK)
	set("theme_override_colors/font_outline_color",Color.WHITE)
	
	shake = true
	await Game.sleep(0.1)
	shake = false
	position = initial_pos
