extends Node2D
class_name KnockbackComponent

@export var heart : PhysicsBody2D
@export var knockback_vector : Vector2 = Vector2.ZERO #only used for CharacterBody2D

func _ready():
	if not heart:
		heart = get_parent()

func knockback(source,force,direction : Vector2):
	if not source: return
	if not direction or direction == Vector2.ZERO:
		var source_position = get_node(source).position
		var assumed_direction = source_position - heart.position
		Physics.throw(heart,assumed_direction,force)
	else:
		Physics.throw(heart,direction,force)
