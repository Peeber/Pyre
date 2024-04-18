extends Node

func throw(object,target,power,duration : float = 1):
	if object is CharacterBody2D:
		#if object.has_signal("movement_override_ended"):
			#
			#object.velocity += (target.normalized() * power)
			#object.move_and_slide()
			#
			#if duration and duration > 0:
				#if object.movement_override != null:
					#object.movement_override = true
				#
				#var timer = Timer.new()
				#timer.one_shot = true
				#timer.wait_time = duration
				#timer.timeout.connect(func():
					#halt(object)
					#object.move_and_slide()
				#)
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
		
		var timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = duration
		timer.timeout.connect(func():
			knockback.knockback_vector -= force_vector
			timer.queue_free()
		)
	elif object is RigidBody2D:
		object.apply_central_impulse((target.normalized()) * power) #why is this so much easier

func halt(object):
	object.linear_velocity = Vector2.ZERO
	if object.has_signal("movement_override_ended"):
		object.movement_override_ended.emit()
		object.movement_override = false
