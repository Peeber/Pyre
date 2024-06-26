extends Resource
class_name Ability

@export var ability_name: String = ""
@export var texture: Texture2D
@export_multiline var description: String = ""
@export var aim_type: String = ""
@export var cost = 100
@export var scene : PackedScene
@export var allowed_weapons : Array[Weapon]
@export var is_parented : bool = false
