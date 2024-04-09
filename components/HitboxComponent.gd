extends Area2D
class_name HitboxComponent

@export var health_component : HealthComponent
@export var knockback_component : KnockbackComponent
@export var isImmune : bool = false #immune to damage
@export var isImmovable: bool = false #immune to knockback

func damage(attack: Attack):
	if health_component and not isImmune:
		health_component.damage(attack)
	if knockback_component and not isImmovable:
		knockback_component.knockback(attack.source,attack.knockback_force,attack.knockback_direction)

