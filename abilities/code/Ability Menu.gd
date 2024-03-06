extends Control

@export var items: Array[Ability]
@onready var menu = $ScrollContainer/HBoxContainer
@onready var toggleDebounce = $ToggleDebounce

var cantToggle = false
var selectedSlot : int = 0
var selectedIcon : AbilityIcon
signal menuRefreshed

#bind all signals, make sure gui is closed
func _ready():
	close()
	if !SignalBus.is_connected("addedAbility",add_ability):
		SignalBus.addedAbility.connect(add_ability)
	if !SignalBus.is_connected("changedAbility",replace_ability):
		SignalBus.changedAbility.connect(replace_ability)
	if !SignalBus.is_connected("askedForAbility",find_ability):
		SignalBus.askedForAbility.connect(find_ability)
	if !SignalBus.is_connected("openedAbilityMenu",open):
		SignalBus.openedAbilityMenu.connect(open)
	if !SignalBus.is_connected("closedAbilityMenu",close):
		SignalBus.closedAbilityMenu.connect(close)
	refresh()

func _unhandled_input(_event: InputEvent) -> void:
	if !State.paused: return
	if Input.is_action_just_pressed("ember") and State.scriptedAbility == false and cantToggle == false:
		SignalBus.closedAbilityMenu.emit()
	elif Input.is_action_just_pressed("ui_right"):
		if !selectedIcon:
			return
		selectedIcon.offSelect()
		var slots = menu.get_children().size()
		if selectedSlot >= slots-1:
			selectedSlot = 0
		else:
			selectedSlot += 1
		selectedIcon = menu.get_child(selectedSlot)
		selectedIcon.onSelect()
		

func add_ability(ability_name: String):
	var ability: Ability = load("res://abilities/menu/" + ability_name + ".tres")
	if ability:
		items.append(ability)
	else:
		print("cannot find ability " + ability_name)
	refresh()
	

func remove_ability(ability_name: String):
	var ability: Ability = load("res://abilities/menu/" + ability_name + ".tres")
	if find_ability(ability_name)[0]:
		items.erase(ability)
		refresh()
	else:
		print("could not find " + ability_name + " in the ability array")

func replace_ability(ability_name: String, old: String):
	var ability: Ability = load("res://abilities/menu/" + ability_name + ".tres")
	var ans = find_ability(old)
	if ans[0] == true:
		print(ans[1] + " is being replaced")
		items[ans[1]] = ability
		print("replaced " + old + " with " + items[ans[1]].ability_name)
		return
	else:
		print("player does not have " + old + ", adding instead")
		items.append(ability)
	refresh()

func find_ability(ability_name):
	var count = 0
	for x in items:
		if x.ability_name == ability_name:
			return([true,count])
		count+=1

func refresh():
	#var lastIcon
	for x in menu.get_children():
		x.queue_free()
	for a in items:
		var icon: AbilityIcon = load("res://abilities/menu/AbilityIcon.tscn").instantiate()
		menu.add_child(icon)
		icon.set_sprite(a.texture)
		icon.name = a.ability_name
		icon.custom_minimum_size = Vector2(180,180)
		icon.ability = a
		#icon.focus_mode = Control.FOCUS_ALL
		#if lastIcon:
		#	icon.focus_neighbor_left = lastIcon.get_path()
		#	lastIcon.focus_neighbor_right = icon.get_path()
		#lastIcon = icon
	return true
		

func runDebounce():
	toggleDebounce.start()
	cantToggle = true
	await toggleDebounce.timeout
	cantToggle = false

func close():
	runDebounce()
	visible = false
	State.unpause()

func open():
	runDebounce()
	State.pause()
	var refreshed = refresh()
	if not refreshed:
		State.unpause()
		return
	visible = true
	selectedSlot = 0
	selectedIcon = menu.get_child(0)
	selectedIcon.onSelect()
	print(selectedIcon.name + "selected")
	

