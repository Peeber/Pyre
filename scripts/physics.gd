extends Node

func throw(object,target,power):
	object.apply_central_impulse((target.normalized()) * power)

func halt(object):
	object.linear_velocity = Vector2.ZERO
