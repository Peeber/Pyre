extends Node

func get_all_children(node):
	var nodes : Array = []
	for N in node.get_children():
		if N.get_child_count() > 0:
			nodes.append(N)
			nodes.append_array(get_all_children(N))
		else:
			nodes.append(N)
	return nodes

func find_by_type(parent, type):
	for child in parent.get_children():
		if is_instance_of(child, type):
			return child
		var grandchild = find_by_type(child, type)
		if grandchild != null:
			return grandchild
	return null

#for objects that arent in the scene tree to get nodes
func globally_get_node(path : NodePath):
	return get_node(path)

#fuse two status effects and return a new copy
func fuse_statuses(effect1: StatusEffect, effect2: StatusEffect, facilitator : StatusComponent = null):
	if effect2.effect_name != effect1.effect_name:
		print("WARNING: fused two status effects with different names ",effect1.effect_name, " ", effect2.effect_name)
	
	var new_effect = StatusEffect.new()
	new_effect.effect_name = effect1.effect_name
	
	#steal sources
	for effect in [effect1,effect2]:
		for x in effect.sources:
			if not x in new_effect.sources:
				var result = make_valid_ref_source(x)
				if result:
					new_effect.sources.append(x)
	new_effect.damage = max(effect1.damage,effect2.damage)
	new_effect.step_length = min(effect1.step_length,effect2.step_length)
	new_effect.slowdown = max(effect1.slowdown,effect2.slowdown)
	new_effect.duration = max(effect1.duration,effect2.duration)
	
	if effect1.stackable or effect2.stackable:
		new_effect.stackable = true
		new_effect.stack = max(effect1.stack,effect2.stack)
	
	
	if facilitator:
		var stored_effect = facilitator.active_statuses[new_effect.effect_name]
		if not stored_effect:
			print("WARNING: fused inactive effect " + new_effect.effect_name + ", so timers will not be altered")
		else:
			facilitator
			facilitator.active_statuses[new_effect.effect_name] = new_effect
			if facilitator.heart and facilitator.heart.has_signal("speed_changed"):
				facilitator.heart.speed_changed.emit()
			
			#update timers	
			if facilitator.get_node(new_effect.effect_name + "Duration"):
				var length_timer = facilitator.get_node(new_effect.effect_name + "Duration")
				length_timer.wait_time = new_effect.duration
			if facilitator.get_node(new_effect.effect_name + "Step"):
				var step_timer = facilitator.get_node(new_effect.effect_name + "Step")
				step_timer.wait_time = new_effect.step_length
	return new_effect

#ensures a source for a ref object is a nodepath
func make_valid_ref_source(node):
	if node is NodePath:
		return true
	elif node is Node:
		node = node.get_path()
		return true
	else:
		print("WARNING: tried to make valid source out of non-node ",node, " which is a ", typeof(node))
		return false

#automatically connects all components within a scene assuming they are arranged normally
func auto_link_components(parent : Node):
	var hitbox = Globals.find_by_type(parent,HitboxComponent)
	var health = Globals.find_by_type(parent,HealthComponent)
	var knockback = Globals.find_by_type(parent,KnockbackComponent)
	var status = Globals.find_by_type(parent,StatusComponent)
	var immunity = Globals.find_by_type(parent,ImmunityComponent)
	var hitbox_exists = false
	if hitbox and is_instance_valid(hitbox):
		hitbox_exists = true
		
	if health and is_instance_valid(health):
		if not health.heart or not is_instance_valid(health.heart):
			health.heart = self
		if hitbox_exists:
			hitbox.health_component = health
			
	if knockback and is_instance_valid(knockback):
		if not knockback.heart or not is_instance_valid(knockback.heart):
			knockback.heart = self
		if hitbox_exists:
			hitbox.knockback_component = knockback
			
	if status and is_instance_valid(status):
		if health and is_instance_valid(immunity):
			status.hp = health
		if immunity and is_instance_valid(immunity):
			status.immunity = immunity
		if hitbox_exists:
			hitbox.status_component = status
	if immunity and is_instance_valid(immunity):
		if hitbox_exists:
			hitbox.immunity_component = immunity
