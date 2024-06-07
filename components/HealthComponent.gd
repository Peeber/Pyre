extends Node2D
class_name HealthComponent

@export var MAX_HEALTH = 100.0
@export var current_Health : float :
	set(value):
		current_Health = value
		if current_Health < 0:
			current_Health = 0;
@export var heart : Node #usually the parent, node that this represents the hp of, will be destroyed when hp reaches 0
signal heartKilled
signal damaged(damage)

func _ready():
	current_Health = MAX_HEALTH
	if !heart:
		heart = get_parent()
	

func damage(attack: Attack):
	var dmg = attack.attack_damage
	print(heart.name + " damaged for " + str(dmg))
	current_Health -= dmg
	SignalBus.healthChanged.emit(heart,current_Health,false)
	damaged.emit()
	
	if current_Health <= 0:
		heartKilled.emit()
		

func changeMaxHealth(adjustment):
	MAX_HEALTH += adjustment
	SignalBus.healthChanged.emit(heart,MAX_HEALTH,true)
