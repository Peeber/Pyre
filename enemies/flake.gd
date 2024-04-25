extends Enemy #which is an extension of CharacterBody2D
class_name Flake

func _ready():
	burst_function = blizzard_burst
	burst_thresholds = [200,50]
	await built
	move_target = State.currentPlayer
	switch_move_mode("seek_homing")
	switch_act_mode("random_combo")

var blizzard_burst = func(threshold_reached : float):
	pass

