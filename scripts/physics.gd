extends Node

func throw(object,target,power,duration : float = 1):
	if power == 0:
		return
	if object is CharacterBody2D:
		print("throwing characterbody " + object.name)
		var force_vector = Vector2.ZERO
		force_vector = target.normalized() * power
		var knockback : KnockbackComponent
		for x in object.get_children():
			if x is KnockbackComponent:
				knockback = x
		
		if not knockback:
			print("WARNING: attempted to Physics.throw " + object.name + " that does not have a discernible KnockbackComponent and therefore cannot be thrown as a CharacterBody2D \n if this is intentional, please make the object immovable using its HitboxComponent")
			return
		
		knockback.knockback_vector += force_vector
		
		print("throwing " + object.name + " with force ",force_vector)
		
		get_tree().create_timer(duration).timeout.connect(func():
			if knockback:
				knockback.knockback_vector -= force_vector
		)
	elif object is RigidBody2D:
		object.apply_central_impulse((target.normalized()) * power) #why is this so much easier

func halt(object):
	if object is RigidBody2D:
		object.linear_velocity = Vector2.ZERO
		if object.has_signal("movement_override_ended"):
			object.movement_override_ended.emit()
			object.movement_override = false
	elif object is CharacterBody2D:
		object.velocity = Vector2.ZERO
		object.move_and_slide()
		if object.has_signal("movement_override_ended"):
			object.movement_override_ended.emit()
			object.movement_override = false

func get_generalized_velocity(object):
	var generalized_velocity : Vector2
	if object is CharacterBody2D:
		generalized_velocity = object.velocity
	elif object is StaticBody2D:
		generalized_velocity = object.constant_linear_velocity
	elif object is RigidBody2D:
		generalized_velocity = object.linear_velocity
	else:
		generalized_velocity = Vector2.ZERO
	return generalized_velocity
