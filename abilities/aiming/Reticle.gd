extends CharacterBody2D

@export var speed : int = 35
@export var active : bool = false

func handleInput():
	if State.paused and active:
		var moveDirection = Input.get_vector("ui_left","ui_right","ui_up","ui_down")
		velocity = moveDirection*speed
	
func _physics_process(delta):
	handleInput()
	move_and_slide()
