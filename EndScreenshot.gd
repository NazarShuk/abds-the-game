extends TextureRect

func _enter_tree():
	if EndGameSingleton.screenshot:
		texture = EndGameSingleton.screenshot
