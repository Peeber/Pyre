extends CharacterBody2D
class_name Player

@onready var animations = $AnimationPlayer
@onready var facing = $Direction
@onready var actionable_finder: Area2D = $Direction/ActionableFinder
@onready var hitbox = $HitboxComponent
@onready var health = $HealthComponent
@onready var knockback = $KnockbackComponent
@onready var status = $StatusComponent
@onready var immunity = $ImmunityComponent
@onready var dashFrames = $DashFrames
@onready var dashCD = $DashCD
@onready var focusTimer = $FocusTimer
@export var base_speed: int = 75 :
	set(value): 
		base_speed = value
		speed_changed.emit();
@export var speed = 0
@export var isDashVariant: bool = false
@export var focus = 0
@export var focusTick: float = (5/3.0)
@export var direction = "Right"
@export var embers = 1
@export var weapons : Array[Weapon] = []
@export var iFrameLength : float = 2.5
@export var movement_override : bool = false

signal movement_override_ended
signal speed_changed
signal components_relinked

var isWalking = false
var canDash = true
var isDashing = false
var isTalking = false
var flashModulate = Color(1,1,1,0.6)
var standardModulate = Color(1,1,1,1)
var moving_velocity : Vector2 = Vector2.ZERO

func _ready():
	if !SignalBus.is_connected("dialogueBegan",dialogueStart):
		SignalBus.dialogueBegan.connect(dialogueStart)
	if !SignalBus.is_connected("dialogueEnded",dialogueEnd):
		SignalBus.dialogueEnded.connect(dialogueEnd)
	if !SignalBus.is_connected("teleportedTo",teleportTo):
		SignalBus.teleportedTo.connect(teleportTo)
	if !SignalBus.is_connected("arenaModeSet",handleArenaMode):
		SignalBus.arenaModeSet.connect(handleArenaMode)
	if !SignalBus.is_connected("abilityCast",consolidateEmber):
		SignalBus.abilityCast.connect(consolidateEmber)
	if !health.is_connected("heartKilled",death):
		health.heartKilled.connect(death)
	if !is_connected("speed_changed",calculate_speed):
		speed_changed.connect(calculate_speed)
	State.currentPlayer = self
	speed = base_speed

func addWeapon(weapon : String):
	var new_weapon = load("res://abilities/weapons/" + weapon + ".tres")
	if new_weapon and !(new_weapon in weapons):
		weapons.append(new_weapon)
		print("gave " + weapon + " to player")
		return true
	return false
	

func removeWeapon(weapon : String):
	for x in weapons:
		if x.name == weapon:
			var index = weapons.find(x)
			weapons.remove_at(index)
			print("removed " + weapon + " from player")
			return true
	return false
	

func handleInput():
	if State.paused: return
	if isTalking == false and isDashing == false:
		var moveDirection = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
		if not movement_override: moving_velocity = moveDirection.normalized() * speed
		

func updateAnimation():
		if velocity.length() == 0:
			isWalking = false
			if animations.is_playing():
				animations.stop()
		else:
			isWalking = true
			direction = "Right"
			facing.rotation_degrees = 0
			$Skeleton2D/pelvis.scale.x = 1
			if velocity.x < 0: direction = "Left"; facing.rotation_degrees = 90; $Skeleton2D/pelvis.scale.x = -1
			elif velocity.x > 0: facing.rotation_degrees = 270
			elif velocity.y < 0: facing.rotation_degrees = 180
			
			if isDashing == true:
				print("play dash animation")
				#insert dash animation code here
			else:
				animations.play("run")
				

func _unhandled_input(_event: InputEvent) -> void:
	if State.paused: return
	if Input.is_action_just_pressed("ui_accept"):
		var actionables = actionable_finder.get_overlapping_areas()
		if actionables.size() > 0:
			actionables[0].action()
			return
	elif Input.is_action_just_pressed("dash") and isWalking == true and canDash == true and not movement_override:
		if isDashVariant == false:
			baseDash()
	elif Input.is_action_just_pressed("ember") and State.abilitiesAllowed == true:
		activateAbility()
	#elif Input.is_action_just_pressed("dev_flake_summon"):
		#devFlakeSpawn()
#
#func devFlakeSpawn():
	#print("spawning Flake")
	#var flake = EnemyHandler.spawn("flake",position + Vector2(0,-50))
	#print(flake)
	#flake.build()
	#print("flake built through dev spawn")
	

func activateAbility():
	if State.arenaMode and focus < 100:
		if embers > 0:
			embers -= 1
			SignalBus.emberChanged.emit(embers)
		else:
			return
	SignalBus.openedAbilityMenu.emit()
	

func handleArenaMode(is_active):
	if is_active:
		focusTimer.start()
		print("focus started")
	else:
		focusTimer.stop()
		print("focus stopped")

func baseDash():
	if isDashVariant == false:
			canDash = false
			isDashing = true
			moving_velocity = moving_velocity * 2
			var stored_knockback = knockback.knockback_vector
			immunity.make_immune_to("damage", true)
			immunity.make_immune_to("knockback",true)
			dashFrames.start()
			await dashFrames.timeout
			immunity.make_immune_to("damage",false)
			immunity.make_immune_to("knockback",false)
			isDashing = false
			dashCD.start()
			await dashCD.timeout
			canDash = true

func dialogueStart():
	isTalking = true
	velocity = Vector2.ZERO
	Physics.halt(self)
	move_and_slide()
	updateAnimation()
	

func dialogueEnd():
	isTalking = false
	

func teleportTo(new_position):
	global_position = new_position
	print("player is now at " + str(global_position))
	

func _physics_process(_delta):
	handleInput()
	velocity = moving_velocity
	if not immunity.is_immune_to("knockback"):
		velocity += knockback.knockback_vector
	move_and_slide()
	updateAnimation()
	

func _on_focus_timer_timeout():
	if focus == 100:
		return
	elif focus + focusTick > 100:
		focus = 100
	else:
		focus += focusTick
	SignalBus.focusChanged.emit(focus)
	
func consolidateEmber(caster,ability,target,isEmber = false):
	if ability.ability_name == "Consolidate Ember":
		if target is Player:
			if embers < State.emberMax:
				print("adding ember")
				embers += 1
				SignalBus.emberChanged.emit(embers)
		else:
			State.failedCast(caster,isEmber)

func death():
	print("man im dead")

func _on_hitbox_component_damaging_hit():
	immunity.make_immune_to("damage",true,iFrameLength)

func _on_immunity_component_immune_changed(immunity_type,is_immune):
	if immunity_type != "damage":
		return
	if is_immune:
		modulate = flashModulate
	else:
		modulate = standardModulate

func relink_components():
	Globals.auto_link_components(self)
	hitbox = Globals.find_by_type(self,HitboxComponent)
	health = Globals.find_by_type(self,HealthComponent)
	knockback = Globals.find_by_type(self,KnockbackComponent)
	status = Globals.find_by_type(self,StatusComponent)
	immunity = Globals.find_by_type(self,ImmunityComponent)
	components_relinked.emit()

func calculate_speed():
	var slowdown_amount = 0
	if not status or not is_instance_valid(status):
		await components_relinked
	if status and is_instance_valid(status):
		for x in status.active_statuses.values():
			if "slowdown" in x:
				slowdown_amount -= x.slowdown
	
	speed = base_speed + slowdown_amount


func _on_health_component_damaged(damage):
	SignalBus.healthChanged.emit(self,health.current_health,false)
