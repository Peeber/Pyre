extends Area2D
class_name HitboxComponent

@export var health_component : HealthComponent
@export var knockback_component : KnockbackComponent
@export var status_component : StatusComponent
@export var immunity_component : ImmunityComponent
@export var area: CollisionShape2D

signal hit
signal damaging_hit
signal knocking_hit

func _ready():
	if not area:
		area = Globals.find_by_type(self,CollisionShape2D)
	if not area:
		print("WARNING: HitboxComponent inside " + get_parent().name + " does not have a shape and will not function")

func damage(attack: Attack):
	if not area:
		area = Globals.find_by_type(self,CollisionShape2D)
	hit.emit()
	if health_component and is_instance_valid(health_component):
		if not(immunity_component and is_instance_valid(immunity_component) and immunity_component.is_immune_to("damage")):
			health_component.damage(attack.attack_damage)
			damaging_hit.emit()
	if knockback_component and is_instance_valid(knockback_component):
		if not(immunity_component and is_instance_valid(immunity_component) and immunity_component.is_immune_to("knockback")):
			if attack.knockback_force and attack.knockback_force != 0.0:
				knockback_component.knockback(attack.source,attack.knockback_force,attack.knockback_direction)
				knocking_hit.emit()
	if status_component and is_instance_valid(status_component):
		if attack.statuses and attack.statuses != []:
			status_component.process_status_list(attack.statuses)
