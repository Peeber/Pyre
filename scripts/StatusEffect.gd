extends RefCounted
class_name StatusEffect


@export var sources : Array
@export var effect_name : String = "UnnamedEffect"
@export var duration : float = 0.0 #optional duration variable to end it automatically
@export var step_length : float = 0.0 #time between damage ticks, 0.0 if there is no reason to tick
@export var damage : float = 0.0
@export var slowdown : float = 0.0 #multiplied by target speed when applied then restored when the effect ends
@export var stackable : bool = false #if an effect can be stacked for greater effects NOT IMPLEMENTED
@export var stack : float = 1.0 #number of stacks of an effect
@export var gfx_scene_path : String = "" #string of the path to load the gfx scene from
@export var gfx_node_path : NodePath
