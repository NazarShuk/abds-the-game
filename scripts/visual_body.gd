extends Node3D

@onready var default: Node3D = $Default
@onready var freaky: Node3D = $Freaky
@onready var perfect: Node3D = $Perfect
@onready var impossible: Node3D = $Impossible
@onready var disoriented: Node3D = $Disoriented

func _ready() -> void:
	if !multiplayer.has_multiplayer_peer():
		$MultiplayerSynchronizer.queue_free()


func pick_skin(skin_id = -1):
	
	for skin in get_children():
		if skin is Node3D:
			skin.hide()
	
	var picked_skin = false
	
	var picked_skin_id = Achievements.picked_skin
	
	if skin_id != -1:
		picked_skin_id = skin_id
	
	if picked_skin_id == 3:
		impossible.show()
		picked_skin = true
	if picked_skin_id == 2:
		perfect.show()
		picked_skin = true
	if picked_skin_id == 1:
		freaky.show()
		picked_skin = true
	if picked_skin_id == 4:
		disoriented.show()
		picked_skin = true
	if picked_skin_id == 5:
		$Peppino.show()
	
	if picked_skin == false:
		default.show()
