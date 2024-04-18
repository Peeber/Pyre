extends Enemy #which is an extension of CharacterBody2D
class_name Flake

func _ready():
	burst_function = blizzard_burst
	burst_thresholds = [200,50]
	build()
	

var blizzard_burst = func(threshold_reached : float):
	pass

