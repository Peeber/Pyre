extends Area2D

@export var health_component : HealthComponent
@export var isImmune : bool = false

func damage(attack: Attack):
	if health_component and isImmune == false:
		health_component.damage(attack)
