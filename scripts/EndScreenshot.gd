extends TextureRect

func _enter_tree():
	if GlobalVars.screenshot:
		texture = GlobalVars.screenshot
