extends Resource

class_name GameParams

# all parameters must start with param_

@export var param_notebooks_per_player: int = 1
@export var param_starting_notebooks: int = 9
@export var param_max_deaths: int = 9
@export var param_deaths_per_player: int = 1
var higher_is_harder = [
	"param_notebooks_per_player",
	"param_starting_notebooks"
]
var lower_is_harder = [
	"param_max_deaths",
	"param_deaths_per_player"
]

@export var param_vertical_camera: bool = false
@export var param_mr_azzu: bool = true
@export var param_ms_gainy: bool = true
@export var param_mr_misuraca: bool = true
@export var param_ms_leahy: bool = true
@export var param_mr_fox: bool = true
@export var param_vending_machines: bool = true
@export var param_bananas: bool = true
@export var param_coffee_machine: bool = true
@export var param_breaker: bool = true
@export var param_wheel: bool = true
@export var param_the_shop: bool = true
@export var param_absences: bool = true
@export var param_silent_lunch: bool = true

var neutral_parameters = [
	"param_vertical_camera",
	"param_the_shop",
	"param_absences",
	"param_wheel",
	"param_breaker",
	"param_coffee_machine",
	"param_vending_machines"
]

func set_param(name, value):
	set("param_"+ name, value)

func get_param(name):
	return get("param_" + name)
