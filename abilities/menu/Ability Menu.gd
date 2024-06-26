extends Control

@export var items: Array[Ability]
@onready var menu = $ScrollContainer/HBoxContainer
@onready var toggleDebounce = $ToggleDebounce
@onready var textbox = $Description

var cantToggle = false
var selectedSlot : int = 0
var selectedIcon : AbilityIcon
var isOpen = false
var isAiming = false
var freeCast = false
var IconScene = load("res://abilities/menu/AbilityIcon.tscn")
signal menuRefreshed
signal aimEnd

var reticleAim = func():
	isAiming = true
	var player = State.currentPlayer
	var reticle = load("res://abilities/aiming/reticle.tscn").instantiate()
	player.get_parent().add_child(reticle)
	reticle.global_position = player.global_position
	reticle.active = true
	await aimEnd
	reticle.active = false
	var pos = reticle.global_position
	reticle.queue_free()
	return pos
	

var lineAim = func():
	pass
	
var coneAim = func():
	pass

var noAim = func():
	return State.currentPlayer

var aimDict = {
	"Reticle" : reticleAim,
	"Line" : lineAim,
	"Cone" : coneAim,
	"None" : noAim,
}

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

func aim(ability: Ability):
	if not ability.aim_type:
		ability.aim_type = "None"
	var aim_function = aimDict[ability.aim_type]
	isAiming = true
	var target = await aim_function.call()
	isAiming = false
	print(ability.ability_name,target)
	if ability.scene:
		var new_scene = ability.scene.instantiate()
		State.currentPlayer.get_parent().add_child(new_scene)
	SignalBus.abilityCast.emit(State.currentPlayer,ability,target,!freeCast)
	$ColorRect.visible = false
	freeCast = false
	close()
	

func _unhandled_input(_event: InputEvent) -> void:
	if !State.paused or State.scene_changing: return
	if isOpen and visible == false:
		visible = true
	if Input.is_action_just_pressed("ember") and State.scriptedAbility == false and cantToggle == false and isAiming == false:
		State.failedCast(State.currentPlayer,!freeCast)
		SignalBus.closedAbilityMenu.emit()
	elif Input.is_action_just_pressed("ui_right") and isOpen:
		var slots = menu.get_children().size()
		if not selectedIcon:
			selectedSlot = 0
			selectedIcon = menu.get_child(selectedSlot)
		selectedIcon.offSelect()
		if selectedSlot >= slots-1:
			selectedSlot = 0
		else:
			selectedSlot += 1
		selectedIcon = menu.get_child(selectedSlot)
		print("slot " + str(selectedSlot) + " selected")
		selectedIcon.onSelect()
		updateText(selectedIcon.ability)
	elif Input.is_action_just_pressed("ui_left") and isOpen:
		var slots = menu.get_children().size()
		if not selectedIcon:
			selectedSlot = slots-1
			selectedIcon = menu.get_child(selectedSlot)
		selectedIcon.offSelect()
		if selectedSlot == 0:
			selectedSlot = slots-1
		else:
			selectedSlot -= 1
		selectedIcon = menu.get_child(selectedSlot)
		print("slot " + str(selectedSlot) + " selected")
		selectedIcon.onSelect()
		updateText(selectedIcon.ability)
	elif Input.is_action_just_pressed("ui_accept"):
		print("z pressed")
		if selectedSlot != null:
			selectedIcon = menu.get_child(selectedSlot)
			if isAiming == false and isOpen == true:
				isOpen = false
				$ColorRect.visible = true
				visible = false
				aim(selectedIcon.ability)
			elif isAiming == true and isOpen == false:
				aimEnd.emit()
				print("aim ended")
		

func add_ability(ability_name: String,weapon : String):
	var ability: Ability = load("res://abilities/resources/" + weapon + "/" + ability_name + ".tres")
	if ability:
		items.append(ability)
		print("added " + ability_name)
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
		#make sure the player has the right weapon to use the ability
		var allowed = false
		for w in State.currentPlayer.weapons:
			print(w.name)
			print(a.allowed_weapons)
			if w in a.allowed_weapons:
				allowed = true
		if not allowed:
			continue
		
		var icon: AbilityIcon = IconScene.instantiate()
		menu.add_child(icon)
		icon.set_sprite(a.texture)
		icon.name = a.ability_name
		icon.custom_minimum_size = Vector2(180,180)
		icon.ability = a
	menuRefreshed.emit()
		

func runDebounce():
	toggleDebounce.start()
	cantToggle = true
	await toggleDebounce.timeout
	cantToggle = false

func close():
	isOpen = false
	runDebounce()
	visible = false
	State.unpause()
	freeCast = false

func updateText(ability : Ability):
	var ability_name = "[font_size=36][center]" + ability.ability_name + "[/center][/font_size]"
	var description = "[font_size=28][center]" + ability.description + "[/center][/font_size]"
	textbox.text = ability_name + "\n" + description

func open():
	if State.scene_changing:
		return
	isOpen = true
	runDebounce()
	State.pause()
	refresh()
	await menuRefreshed
	visible = true
	selectedSlot = 0
	selectedIcon = menu.get_child(0)
	if not selectedIcon:
		State.unpause()
		visible = false
		isOpen = false
		print("tried to open ability menu with no valid abilities")
		return
	selectedIcon.onSelect()
	updateText(selectedIcon.ability)
	print(selectedIcon.ability.ability_name)
	if State.currentPlayer.focus == 100:
		State.currentPlayer.focus = 0
		freeCast = true
	
