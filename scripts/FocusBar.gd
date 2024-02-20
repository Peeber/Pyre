extends ProgressBar

@onready var timer = Timer
@export var player : Player

# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false



func update():
	value = player.focus
