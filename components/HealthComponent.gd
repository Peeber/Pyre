extends Node2D
class_name HealthComponent

@export var MAX_HEALTH = 100.0
@export var current_Health : float
@export var heart : Node #usually the parent, node that this represents the hp of, will be destroyed when hp reaches 0
signal heartKilled

func _ready():
	current_Health = MAX_HEALTH
	if !heart:
		heart = get_parent()
	

func damage(attack: Attack):
	print(heart.name + " damaged for " + str(attack.attack_damage))
	current_Health -= attack.attack_damage
	SignalBus.healthChanged.emit(heart,current_Health,false)
	
	if current_Health <= 0:
		heartKilled.emit()
		

func changeMaxHealth(adjustment):
	MAX_HEALTH += adjustment
	SignalBus.healthChanged.emit(heart,MAX_HEALTH,true)
