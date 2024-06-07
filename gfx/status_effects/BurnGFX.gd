extends Sprite2D

@onready var timer = $Timer
@onready var animator = $AnimationPlayer

func _ready():
	while is_instance_valid(self):
		animator.play("burn")
		await animator.animation_finished
