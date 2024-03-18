extends CharacterBody2D
class_name Player

@onready var animations = $AnimationPlayer
@onready var facing = $Direction
@onready var actionable_finder: Area2D = $Direction/ActionableFinder
@onready var hitbox = $HitboxComponent
@onready var health = $HealthComponent
@onready var dashFrames = $DashFrames
@onready var dashCD = $DashCD
@onready var focusTimer = $FocusTimer
@export var speed: int = 75
@export var isDashVariant: bool = false
@export var focus = 0
@export var focusTick: int = (5/3.0)
@export var direction = "Right"
@export var embers = 1

var isWalking = false
var canDash = true
var isDashing = false
var isTalking = false

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
	State.currentPlayer = self

func handleInput():
	if State.paused: return
	if isTalking == false and isDashing == false:
		var moveDirection = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
		velocity = moveDirection*speed
		

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
	elif Input.is_action_just_pressed("dash") and isWalking == true and canDash == true:
		if isDashVariant == false:
			baseDash()
	elif Input.is_action_just_pressed("ember") and State.abilitiesAllowed == true:
		activateAbility()

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
			velocity = velocity * 2
			hitbox.isImmune = true
			dashFrames.start()
			await dashFrames.timeout
			hitbox.isImmune = false
			isDashing = false
			dashCD.start()
			await dashCD.timeout
			canDash = true

func dialogueStart():
	isTalking = true
	velocity = velocity * 0
	updateAnimation()
	

func dialogueEnd():
	isTalking = false
	

func teleportTo(new_position):
	global_position = new_position
	print("player is now at " + str(global_position))
	

func _physics_process(delta):
	handleInput()
	move_and_slide()
	updateAnimation()
	

func _on_focus_timer_timeout():
	if focus == 100:
		print("focus full")
		return
	elif focus + focusTick > 100:
		focus = 100
		print("focus filled")
	else:
		focus += focusTick
		print("focus increased")
	print("focus changed")
	SignalBus.focusChanged.emit(focus)
	
func consolidateEmber(caster,ability, target):
	if ability.ability_name == "Consolidate Ember" and target is Player:
		if embers < State.emberMax:
			embers += 1
			SignalBus.emberChanged.emit(embers)
