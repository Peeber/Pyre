extends StaticBody2D
class_name Destructible

@onready var hitbox = $HitboxComponent
@onready var hp = $HealthComponent
@export var regenerative : bool = false
@export var regen_time : int = 45
@export var collision_shape : CollisionShape2D
@export var hitbox_shape : CollisionShape2D :
	set(value): 
		if hitbox and value != hitbox.area:
			overwrite_hitbox_shape(value)
		else:
			hitbox_shape = value;
@export var on_destroyed : Callable :
	get: return on_destroyed;
	set(value): on_destroyed = value;
@export var base_hp : float = 100.0


func _ready():
	if not hitbox_shape:
		hitbox_shape = get_node_or_null("HitboxShape")
	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape")
	if hitbox_shape:
		if not hitbox.area:
			overwrite_hitbox_shape(hitbox_shape)
	hp.MAX_HEALTH = base_hp
	hp.current_health = base_hp

func overwrite_hitbox_shape(shape):
	var new_shape = shape.duplicate()
	hitbox.add_child(new_shape)
	hitbox.area = new_shape
	shape.queue_free()
	hitbox_shape = new_shape

func false_destroy():
	hide()
	hitbox.monitorable = false
	if collision_shape:
		collision_shape.set_deferred("disabled",true)

func respawn():
	show()
	hitbox.monitorable = true
	if collision_shape:
		collision_shape.set_deferred("disabled",false)
	hp.current_health = hp.MAX_HEALTH

func _on_health_component_heart_killed():
	on_destroyed.call_deferred()
	if regenerative:
		false_destroy()
		get_tree().create_timer(regen_time).timeout.connect(respawn,4)
	else:
		queue_free()

