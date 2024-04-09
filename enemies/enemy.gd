extends CharacterBody2D
class_name Enemy

@export var hitbox : HitboxComponent :
	get: return hitbox;
	set(value): hitbox = value;
@export var hp : HealthComponent :
	get: return hp;
	set(value): hp = value;
@export var knockback : KnockbackComponent :
	get: return knockback;
	set(value): knockback = value;
@export var death_function : Callable :
	get: return death_function;
	set(value) : death_function = value;
@export var burst_function : Callable :
	get: return burst_function;
	set(value) : burst_function = value;
@export var burst_thresholds : Array[float] :
	get: return burst_thresholds;
	set(value): burst_thresholds = value;
@export var navigation_agent : NavigationAgent2D :
	get: return navigation_agent;
	set(value): navigation_agent = value
@export var act_mode : String = "none" :
	get: return act_mode;
	set(value): act_mode = value;
@export var move_mode : String = "stationary" :
	get: return move_mode;
	set(value): move_mode = value;
@export var speed : int :
	get: return speed;
	set(value): speed = value;
@export var move_target : Node2D :
	get: return move_target;
	set(value): move_target = value;
@export var attack_target : Node2D = State.currentPlayer :
	get: return attack_target;
	set(value): attack_target = value;
@export var aggression : float = 0.5 :
	get: return aggression;
	set(value) : aggression = value;
@export var intelligence : int = 0 :
	get: return intelligence;
	set(value): intelligence = value;
@export var move_frequency : float = 1 :
	get: return move_frequency;
	set(value): move_frequency = value;
@export var move_timer : Timer :
	get: return move_timer;
	set(value): move_timer = value
@export var act_timer : Timer :
	get: return act_timer;
	set(value): act_timer = value;
@export var movelist : Array[Ability] = [] :
	get: return movelist;
	set(value) : movelist = value;
@export var combolist : Array :
	get: return combolist;
	set(value) : combolist = value;
@export var mulligan : bool = false : #makes enemy not get deleted when hp reaches 0
	get: return mulligan;
	set(value): mulligan = value;

var rand=RandomNumberGenerator.new()
var pathfinding = false

signal swapped_move_mode
signal swapped_attack_mode
signal ready_to_free

var death_mode = func():
	print(name + "has died")
	if death_function:
		death_function.call()
		await ready_to_free
	if not mulligan:
		self.queue_free()

func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	if pathfinding:
		if velocity == Vector2.ZERO:
			pathfinding = false
			move_and_slide()
			return
		if intelligence > 0:
			velocity = safe_velocity.normalized() * speed
		move_and_slide()

var seek_mode = func():
	if not pathfinding:
		pathfinding = true
	if not move_target: return
	
	navigation_agent.set_velocity((move_target.global_position - global_position).normalized() * speed)
	
	swapped_move_mode.connect(func():
		navigation_agent.set_velocity(Vector2.ZERO)
	)

var seek_homing_mode = func():
	if not pathfinding:
		pathfinding = true
	if not move_target: return
	
	var seek_timer = Timer.new()
	seek_timer.one_shot = false
	seek_timer.duration = (1.0 - aggression)
	
	seek_timer.timeout.connect(func():
		navigation_agent.set_velocity((move_target.global_position - global_position).normalized() * speed)
	)
	
	swapped_move_mode.connect(func():
		seek_timer.queue_free()
		navigation_agent.set_velocity(Vector2.ZERO)
	)

var stay_mode = func(duration : float):
	pathfinding = false
	navigation_agent.set_velocity(Vector2.ZERO)

var move_modes = {
	"death" = death_mode,
	"seek" = seek_mode,
	"seek_homing" = seek_homing_mode,
	"stationary" = stay_mode,
}

var random_attack_mode = func():
	while act_mode == "random_attack":
		rand.randomize()
		var index = rand.randi_range(0,movelist.size()-1)
		activate_ability(movelist[index])
		act_debounce

var random_combo_mode = func():
	while act_mode == "random_combo":
		if !combolist or combolist == []:
			switch_act_mode("random_attack")
			return
		rand.randomize()
		var index = rand.randi_range(0,combolist.size()-1)
		var combo = combolist[index]
	
		for ability in combo:
			activate_ability(ability)
		act_debounce()
	

var act_modes = {
	"none" = null,
	"random_attack" = random_attack_mode,
	"random_combo" = random_combo_mode,
}

func switch_move_mode(mode : String):
	var mode_func : Callable = move_modes[mode]
	if !(mode_func is Callable) or not mode_func :
		print("invalid move mode, aborting")
		return
	move_mode = mode
	mode_func.call()

func switch_act_mode(mode : String):
	var mode_func : Callable = act_modes[mode]
	if mode == "none":
		act_mode = "none"
		return
	elif !(mode_func is Callable) or not mode_func :
		print("invalid move mode, aborting")
		return
	act_mode = mode
	mode_func.call()

func death():
	switch_act_mode("none")
	switch_move_mode("death")

func activate_ability(ability : Ability):
	if ability.scene:
		var new_scene = ability.scene.instantiate()
		self.get_parent().add_child(new_scene)
	SignalBus.abilityCast.emit(self,ability,attack_target,false)

func act_debounce():
	act_timer.wait_time = aggression
	act_timer.start()
	await act_timer.timeout
	return true

func check_burst():
	pass

func build():
	if not hitbox:
		for x in get_children():
			if x is HitboxComponent:
				hitbox = x
	if not hp:
		for x in get_children():
			if x is HealthComponent:
				hp = x
				hp.damaged.connect(check_burst)
	if not knockback:
		for x in get_children():
			if x is KnockbackComponent:
				knockback = x
	if not navigation_agent:
		for x in get_children():
			if x is NavigationAgent2D:
				navigation_agent = x
	if not hp or not hitbox:
		print(name + " has been created without the required components and will be invulnerable (and might crash the game)")
	hp.heartKilled.connect(death)
	act_timer = Timer.new()
	act_timer.one_shot = true
	act_timer.wait_time = aggression
	move_timer = Timer.new()
	move_timer.one_shot = true
	move_timer.wait_time = move_frequency
	
