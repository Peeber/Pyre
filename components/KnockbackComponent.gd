extends Node
class_name KnockbackComponent

@export var heart : PhysicsBody2D
@export var knockback_vector : Vector2 = Vector2.ZERO #only used for CharacterBody2D

func _ready():
	if not heart:
		heart = get_parent()

func knockback(source,force,direction : Vector2):
	if not heart:
		heart = get_parent()
	if force == 0.0:
		return
	if not direction or direction == Vector2.ZERO:
		if not source: return
		if "position" in get_node(source):
			var source_position = get_node(source).position
			var assumed_direction = source_position - heart.position
			Physics.throw(heart,assumed_direction,force)
		else:
			if not source:
				print("where did the source of this knockback go??? target was " + heart.name)
				return
			print("source " + get_node(source).name + " does not have a position and so " + heart.name + " cannot be knocked back")
	else:
		Physics.throw(heart,direction,force)
