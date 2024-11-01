extends Panel

func set_item(node):
	for child in $SubViewportContainer/SubViewport/ItemHold.get_children():
		child.queue_free()
	$SubViewportContainer/SubViewport/ItemHold.add_child(node)

func select():
	$ColorRect.hide()

func unselect():
	$ColorRect.show()
