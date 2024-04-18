extends Area2D

@export var caster : Node2D
@export var hit_cd : Timer

var attack : Attack
var targets : Array[HitboxComponent] = []

func _ready():
	if not hit_cd:
		hit_cd = $Timer
	if not caster:
		caster = get_parent()

func enable(current_attack : Attack):
	if !monitoring:
		monitoring = true
	attack = current_attack

func disable():
	monitoring = false
	attack = null

func _on_area_entered(area):
	if area.get_parent() == caster:
		return
	targets.append(area)

func _on_area_exited(area):
	if area in targets:
		targets.remove_at(targets.find(area))

