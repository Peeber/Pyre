extends Resource
class_name Attack

@export var source : NodePath
@export var attack_damage : float = 1.0
@export var knockback_force : float = 0.0
@export var knockback_direction : Vector2
@export var statuses : Array #ex. [{"Name" = "Burn", "Intensity" = 1, "Duration" = 10}]
