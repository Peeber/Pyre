extends Node2D
class_name KnockbackComponent

@export var parent = get_parent()

func knockback(source,force,direction : Vector2):
	if not source: return
	if not direction:
		var source_position = get_node(source).position
		var assumed_direction = source_position - parent.position
		Physics.throw(parent,assumed_direction,force)
	else:
		Physics.throw(parent,direction,force)
