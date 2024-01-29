extends ProgressBar

@export var player : Player

func _ready():
	update()

func update():
	max_value = player.max_Health
	value = player.current_Health
	
