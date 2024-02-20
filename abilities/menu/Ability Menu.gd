extends Control

@export var items: Array[Ability]
@onready var menu = $HBoxContainer

func _ready():
	if !SignalBus.is_connected("addedAbility",add_ability):
		SignalBus.addedAbility.connect(add_ability)
	if !SignalBus.is_connected("changedAbility",replace_ability):
		SignalBus.changedAbility.connect(replace_ability)

func add_ability(name: String):
	var ability: Ability = load("res://abilities/menu/" + name + ".tres")
	items.append(ability)

func replace_ability(name: String, old: String):
	var success = false
	var ability: Ability = load("res://abilities/menu/" + name + ".tres")
	for x in items:
		if x.name == old:
			var index = items.bsearch(x)
			print(old + " is at " + index)
			items[index] = ability
			print("replaced " + old + " with " + items[index].name)
			success = true
			break
	if !success:
		print("player does not have " + old + ", adding instead")
		items.append(ability)

func refresh():
	pass
