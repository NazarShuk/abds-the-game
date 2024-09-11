extends Node3D

@onready var explosion = $Explosion
@onready var explosion_2 = $Explosion2
@onready var explosion_3 = $Explosion3


func _ready():
	explosion.emitting = true
	explosion_2.emitting = true
	explosion_3.emitting = true
