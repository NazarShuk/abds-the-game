extends Node2D

func  _ready():
	$CanvasLayer/ColorRect/Label.text = Allsingleton.steam_error + "\n\n Please restart the game"
