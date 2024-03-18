extends RigidBody2D
class_name Spark

@onready var ThrowTime = $ThrowTime
@onready var area = $Area2D
@export var source : PhysicsBody2D
@export var target : Vector2
@export var force = 250
signal ready_to_fire

var attack = Attack.new()
var resource = load("res://abilities/menu/Spark.tres")
var is_fired = false
var ownedLasers = []

func _ready():
	if !SignalBus.is_connected("abilityCast",abilityCast):
		SignalBus.abilityCast.connect(abilityCast)
	visible = false

func abilityCast(caster,ability : Ability, pos):
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
	var detected = area.get_overlapping_bodies()
	if detected.size() > 0:
		setupAttack()
		for x in detected:
			if x is Spark and x != self:
				createBeam(x)

func setupAttack():
	attack.attack_damage = 2.5
	attack.knockback_force = 0
	attack.canIgnite = true

func createBeam(target):
	print("creating beam to spark at ",target.position)
	var laser : LaserBeam = load("res://addons/BulletUpHell/BulletScene/LaserBeam.tscn").instantiate()
	laser.set_collide_with(2)
	target.add_child(laser)
	#i wish i could tell you why this works but i cant, very likely the function that builds the laser's ray uses global position
	laser.global_position = target.position
	laser.set_update_cooldown(0.5)
	laser.set_laser_length(target.global_position.distance_to(global_position))
	laser.look_at(position)
	laser.collided.connect(onHit)
	ownedLasers.append(laser)
	
func onHit(pos, collider, normal_vector):
	print("hit ",collider)
	var hitbox : HitboxComponent
	var children_list = collider.get_children()
	for x in children_list:
		if x is HitboxComponent:
			hitbox = x
	print("hit" + collider.name)
	hitbox.damage(attack)

