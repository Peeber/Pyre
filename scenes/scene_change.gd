extends Node

var next_world : Node2D
var old_camera : PhantomCamera2D
var new_camera : PhantomCamera2D

@onready var current_world = $test_world
@onready var anim = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	if !SignalBus.is_connected("sceneChanged",changeScene):
		SignalBus.sceneChanged.connect(changeScene)


func changeScene(next_world_name: String):
	print("changing scene from " + current_world.name + " to " + next_world_name)
	next_world = load("res://scenes/rooms/" + next_world_name + ".tscn").instantiate()
	next_world.z_index = -1
	add_child(next_world)
	anim.play("fade_in")
	

func _on_animation_player_animation_finished(anim_name):
	old_camera = current_world.get_node("PhantomCamera2D")
	match anim_name:
		"fade_in":
			new_camera = next_world.get_node("PhantomCamera2D")
			new_camera.set_tween_on_load(false)
			old_camera.set_priority(0)
			new_camera.set_priority(1)
			current_world.remove_child(old_camera)
			old_camera = null
			
			current_world.queue_free()
			for x in next_world.get_children(true):
				if x is Door:
					if x.nextWorldName == current_world.name:
						SignalBus.teleportedTo.emit(Door.global_position)
			current_world = next_world
			current_world.z_index = 0
			next_world = null
			anim.play("fade_out")
		"fade_out":
			new_camera.set_tween_on_load(true)
			old_camera = new_camera
			new_camera = null
