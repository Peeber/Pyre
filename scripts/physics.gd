extends Node

func throw(object,target,power):
	if object is CharacterBody2D:
		print("ayo impulses on characters dont have a workaround yet")
		return
	else:
		object.apply_central_impulse((target.normalized()) * power)

func halt(object):
	object.linear_velocity = Vector2.ZERO
