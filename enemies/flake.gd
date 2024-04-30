extends Enemy #which is an extension of CharacterBody2D
class_name Flake

func _ready():
	burst_function = blizzard_burst
	burst_thresholds = [200,50]

var blizzard_burst = func(threshold_reached : float):
	pass

func _on_built():
	move_target = State.currentPlayer
	act_debounce()
	switch_move_mode("seek_homing")
	switch_act_mode("none")
