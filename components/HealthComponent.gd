extends Node
class_name HealthComponent

@export var MAX_HEALTH = 100.0
@export var current_health : float :
	set(value):
		current_health = value
		if current_health < 0:
			current_health = 0;
@export var heart : Node #usually the parent, node that this represents the hp of, will be destroyed when hp reaches 0
signal heartKilled
signal damaged(damage)

func _ready():
	current_health = MAX_HEALTH
	if !heart:
		heart = get_parent()
	

func damage(dmg):
	print(heart.name + " damaged for " + str(dmg))
	current_health -= dmg
	damaged.emit(dmg)
	
	if current_health <= 0:
		heartKilled.emit()
		

func changeMaxHealth(adjustment):
	MAX_HEALTH += adjustment
	SignalBus.healthChanged.emit(heart,MAX_HEALTH,true)
