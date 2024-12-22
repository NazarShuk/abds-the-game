extends AudioStreamPlayer

@onready var cpu_particles_3d: CPUParticles3D = $CPUParticles3D

var spectrum : AudioEffectSpectrumAnalyzerInstance = AudioServer.get_bus_effect_instance(1,0)

@export var threshold = 100
@export var min_frequency = 100

func _process(delta: float) -> void:
	
	var mag = spectrum.get_magnitude_for_frequency_range(min_frequency,min_frequency * 2).length()
	
	if mag * 1000 > threshold:
		var particles : CPUParticles3D = cpu_particles_3d.duplicate()
		add_child(particles)
		particles.emitting = true
	
