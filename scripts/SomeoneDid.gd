extends Label


func _ready():
	Game.on_info_text.connect(_on_info_text)

func _process(delta):
	var clr:Color = get("theme_override_colors/font_color")
	set("theme_override_colors/font_color",clr.lerp(Color(0,0,0,0),0.01))
	
	var outline_color = get("theme_override_colors/font_outline_color")
	set("theme_override_colors/font_outline_color",outline_color.lerp(Color(0,0,0,0),0.01))

func _on_info_text(info):
	text = info
	set("theme_override_colors/font_color",Color.BLACK)
	set("theme_override_colors/font_outline_color",Color.WHITE)
