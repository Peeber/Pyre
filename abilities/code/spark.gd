extends RigidBody2D
class_name Spark

@onready var ThrowTime = $ThrowTime
@onready var area = $Area2D
@export var source : PhysicsBody2D
@export var target : Vector2
@export var force = 250
@export var is_moving = true
signal ready_to_fire

var attack = load("res://resources/Attack.tres")
var resource = load("res://abilities/resources/Ember of Hope/Spark.tres")
var is_fired = false
var ownedLasers = []
var laseredBy = []

func _ready():
	if !SignalBus.is_connected("abilityCast",abilityCast):
		SignalBus.abilityCast.connect(abilityCast)
	visible = false

#insures two lasers cant laser each other for double damage
func claimSpark(claimer):
	if claimer is Spark:
		laseredBy.append(claimer)

func abilityCast(caster,ability : Ability, pos,_isEmber):
	if ability != resource or is_fired == true:
		return
	if caster is Player:
		State.sparkAdded(self)
	position = caster.position
	source = caster
	target = pos
	ready_to_fire.emit()
	
func _on_ready_to_fire():
	if is_fired:
		return
	is_fired = true
	visible = true
	ThrowTime.start()
	Physics.throw(self,target - global_position,force)
	await ThrowTime.timeout
	Physics.halt(self)
	is_moving = false
	var detected = area.get_overlapping_bodies()
	if detected.size() > 0:
		for x in detected:
			if x is Spark and x != self:
				if x.is_moving:
					await x.ThrowTime.timeout
				if laseredBy.find(x) == -1:
					setupAttack()
					print("firing laser")
					x.claimSpark(self)
					createBeam(x)

func setupAttack():
	attack.attack_damage = 5
	attack.knockback_force = 0
	var stat_array = []
	stat_array.append({"Name" = "Burn", "Intensity" = 1, "Duration" = 10})
	attack.statuses = stat_array

func createBeam(beam_target):
	print("creating beam to spark at ",beam_target.position)
	var laser : LaserBeam = load("res://addons/BulletUpHell/BulletScene/LaserBeam.tscn").instantiate()
	laser.set_collide_with(2)
	laser.stay_duration = 999999999
	beam_target.add_child(laser)
	#i wish i could tell you why this works but i cant, very likely the function that builds the laser's ray uses global position
	laser.global_position = beam_target.position
	laser.set_update_cooldown(0.3)
	laser.max_shot_duration = -1
	laser.set_laser_length(beam_target.global_position.distance_to(global_position))
	laser.look_at(position)
	laser.collided.connect(onHit)
	ownedLasers.append(laser)
	
func onHit(pos, collider, _normal_vector):
	print("hit ",collider)
	if collider.get_parent():
		if collider.get_parent() is Spark:
			print("spark hit")
			return
	var hitbox : HitboxComponent
	if collider is HitboxComponent:
		hitbox = collider
	else:
		var children_list = collider.get_children()
		for x in children_list:
			if x is HitboxComponent:
				hitbox = x
	if hitbox:
		print("damaging " + collider.get_parent().name)
		hitbox.damage(attack)

