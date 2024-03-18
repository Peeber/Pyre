extends Node2D
class_name HealthComponent

@export var MAX_HEALTH = 100.0
@export var current_Health : float
var parent = get_parent()

func _ready():
	current_Health = MAX_HEALTH
	

func damage(attack: Attack):
	current_Health -= attack.attack_damage
	SignalBus.healthChanged.emit(parent,current_Health,false)
	
	if current_Health <= 0:
		get_parent().queue_free()

func changeMaxHealth(adjustment):
	MAX_HEALTH += adjustment
	SignalBus.healthChanged.emit(parent,MAX_HEALTH,true)
