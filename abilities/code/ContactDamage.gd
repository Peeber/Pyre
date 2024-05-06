extends Area2D
class_name ContactDamage

@export var caster : Node2D :
	get: return caster;
@export var hit_cd : Timer
@export var shape : CollisionShape2D :
	get: return shape;
	set(value): shape = value;
@export var attack : Attack:
	get: return attack;
	set(value):
		attack = value;
@export var autostart : bool = false :
	get: return autostart;
	set(value): autostart = value;

var targets : Array[HitboxComponent] = [] :
	get: return targets;
	set(value): targets = value;
var hitting_targets : bool = false

func _ready():
	if not hit_cd:
		hit_cd = $Timer
	if monitorable:
		monitorable = false
	if autostart and attack:
		enable(attack)

func enable(current_attack : Attack = null):
	monitoring = true
	if current_attack != attack:
		attack = current_attack

func disable():
	monitoring = false
	attack = null
	hitting_targets = false
	hit_cd.stop()
	if hit_cd.is_connected("timeout",hit_targets):
		hit_cd.timeout.disconnect(hit_targets)
	targets = []

func _on_area_entered(area):
	if area.get_parent() == caster or !(area is HitboxComponent):
		return
	targets.append(area)
	if attack:
		area.damage(attack)
	if not hitting_targets:
		hitting_targets = true
		hit_cd.start()
		if !hit_cd.is_connected("timeout",hit_targets):
			hit_cd.timeout.connect(hit_targets)
		hit_targets()

func _on_area_exited(area):
	if area in targets:
		targets.remove_at(targets.find(area))
	if targets == []:
		hitting_targets = false
		hit_cd.stop()
		if hit_cd.is_connected("timeout",hit_targets):
			hit_cd.timeout.disconnect(hit_targets)

func hit_targets():
	if not attack or not targets:
		return
	for area in targets:
		if !(area is HitboxComponent):
			targets.remove_at(targets.find(area))
			continue
		else:
			hit(area)

func hit(area):
	var temp_attack = attack.duplicate()
	if caster and caster != self:
		var generalized_velocity = Physics.get_generalized_velocity(caster)
		if generalized_velocity != Vector2.ZERO:
			temp_attack.knockback_direction = generalized_velocity.normalized()
	area.damage(temp_attack)
