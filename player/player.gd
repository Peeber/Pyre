extends CharacterBody2D

@onready var animations = $AnimatedSprite2D
@onready var facing = $Direction
@onready var actionable_finder: Area2D = $Direction/ActionableFinder
@onready var hitbox = $HitboxComponent
@onready var dashFrames = $DashFrames
@onready var dashCD = $DashCD
@export var speed: int = 35
@export var isDashVariant: bool = false

var isWalking = false
var canDash = true
var isDashing = false


func handleInput():
	if State.isTalking == false and isDashing == false:
		var moveDirection = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
		velocity = moveDirection*speed

func updateAnimation():
		if velocity.length() == 0:
			isWalking = false
			if animations.is_playing():
				animations.stop()
		else:
			isWalking = true
			var direction = "Down"
			facing.rotation_degrees = 0
			if velocity.x < 0: direction = "Left"; facing.rotation_degrees = 90
			elif velocity.x > 0: direction = "Right"; facing.rotation_degrees = 270
			elif velocity.y < 0: direction = "Up"; facing.rotation_degrees = 180
			
			if isDashing == true:
				print("play dash animation")
				#insert dash animation code here
			else:
				animations.play("walk" + direction)
		

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
			velocity = velocity * 1.5
			hitbox.isImmune = true
			dashFrames.start()
			await dashFrames.timeout
			hitbox.isImmune = false
			isDashing = false
			dashCD.start()
			await dashCD.timeout
			canDash = true
		

func _physics_process(delta):
	handleInput()
	move_and_slide()
	updateAnimation()
	
