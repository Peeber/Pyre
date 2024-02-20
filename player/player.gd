extends CharacterBody2D
class_name Player

@onready var animations = $AnimationPlayer
@onready var facing = $Direction
@onready var actionable_finder: Area2D = $Direction/ActionableFinder
@onready var hitbox = $HitboxComponent
@onready var health = $HealthComponent
@onready var dashFrames = $DashFrames
@onready var dashCD = $DashCD
@export var speed: int = 35
@export var isDashVariant: bool = false
@export var focus = 0
@export var focusTick: int = (5/3)
@export var direction = "Right"

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

func handleInput():
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
	if Input.is_action_just_pressed("ui_accept"):
		var actionables = actionable_finder.get_overlapping_areas()
		if actionables.size() > 0:
			actionables[0].action()
			return
	elif Input.is_action_just_pressed("dash") and isWalking == true and canDash == true:
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
	

func _physics_process(delta):
	handleInput()
	move_and_slide()
	updateAnimation()
	

