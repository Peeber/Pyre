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
@export var triggered_burst_thresholds : Array[float] :
	get: return triggered_burst_thresholds;
	set(value): triggered_burst_thresholds = value;
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
	set(value) :
		aggression = value
		aggression_updated.emit();
@export var intelligence : int = 0 :
	get: return intelligence;
	set(value): intelligence = value;
@export var move_frequency : float = 1 :
	get: return move_frequency;
	set(value):
		move_frequency = value
		move_frequency_updated.emit();
@export var move_timer : Timer :
	get: return move_timer;
	set(value): move_timer = value
@export var act_timer : Timer :
	get: return act_timer;
	set(value): act_timer = value;
@export var move_list : Array[Ability] = [] :
	get: return move_list;
	set(value) : move_list = value;
@export var combo_list : Array = []:
	get: return combo_list;
	set(value) : combo_list = value;
@export var weapon_list : Array[Weapon] = [] :
	get: return weapon_list;
	set(value) : weapon_list = value;
@export var mulligan : bool = false : #makes enemy not get deleted when hp reaches 0
	get: return mulligan;
	set(value): mulligan = value;
@export var movement_override : bool = false :
	get: return movement_override;
	set(value): movement_override = value;
@export var stunned : bool = false :
	get: return stunned;
@export var current_velocity : Vector2 :
	get: return current_velocity;
	set(value): current_velocity = value

var rand = RandomNumberGenerator.new()
var pathfinding = false
var is_swapping_move_mode : bool = false

signal movement_override_ended
signal swapped_move_mode
signal swapped_attack_mode
signal ready_to_free
signal aggression_updated
signal move_frequency_updated
signal built
signal stun_ended
signal action_ended
signal move_mode_swap_debounce_ended

var death_mode = func():
	print(name + "has died")
	if death_function:
		death_function.call()
		await ready_to_free
	if not mulligan:
		self.queue_free()

func _on_move_frequency_updated():
	if move_timer:
		move_timer.wait_time = move_frequency

func _on_aggression_updated():
	if act_timer:
		act_timer.wait_time = 4 * (1 - aggression)

func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	if navigation_agent.is_navigation_finished() == false:
		if pathfinding and not movement_override:
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
	
	if movement_override:
		await movement_override_ended
	if stunned:
		await stun_ended
	navigation_agent.target_position = move_target.global_position
	
	await get_tree().create_timer(0.1).timeout
	swapped_move_mode.connect(func():
		if movement_override:
			await movement_override_ended
		if stunned:
			await stun_ended
		navigation_agent.set_velocity(Vector2.ZERO)
	,4) #4 is the oneshot flag so it disconnects after running

var seek_homing_mode = func():
	print("seek_homing activated")
	if not pathfinding:
		pathfinding = true
	if not move_target: return
	print("homing checks passed")
	var seek_timer = Timer.new()
	seek_timer.name = "SeekTimer"
	add_child(seek_timer)
	seek_timer.one_shot = false
	seek_timer.wait_time = (1.0 - aggression)
	
	seek_timer.timeout.connect(func():
		if movement_override or stunned:
			return
		print("setting target position")
		navigation_agent.target_position = move_target.global_position
	)
	if not movement_override and not stunned:
		navigation_agent.target_position = move_target.global_position
	seek_timer.start()
	
	await get_tree().create_timer(0.1).timeout
	swapped_move_mode.connect(func():
		seek_timer.queue_free()
		await movement_override_ended
		navigation_agent.set_velocity(Vector2.ZERO)
	,4)

var stay_mode = func():
	pathfinding = false
	velocity = Vector2.ZERO
	navigation_agent.set_velocity(Vector2.ZERO)

func _physics_process(delta):
	if navigation_agent.is_navigation_finished() == false and pathfinding:
		velocity = (position.direction_to(navigation_agent.get_next_path_position())) * speed
		navigation_agent.set_velocity(velocity)

var move_modes = {
	"death" = death_mode,
	"seek" = seek_mode,
	"seek_homing" = seek_homing_mode,
	"stationary" = stay_mode,
}

var random_attack_mode = func():
	while act_mode == "random_attack":
		rand.randomize()
		var index = rand.randi_range(0,move_list.size()-1)
		if stunned:
			await stun_ended
		activate_ability(move_list[index])
		await action_ended
		act_debounce()

var random_combo_mode = func():
	while act_mode == "random_combo":
		if !combo_list or combo_list == []:
			print(name + " tried to use random_combo mode but didn't have any combos")
			switch_act_mode("random_attack")
			return
		rand.randomize()
		var index = rand.randi_range(0,combo_list.size()-1)
		var combo = combo_list[index]
	
		for ability in combo:
			if stunned:
				await stun_ended
			activate_ability(ability)
		act_debounce()
	

var act_modes = {
	"none" = null,
	"random_attack" = random_attack_mode,
	"random_combo" = random_combo_mode,
}

func switch_move_mode(mode : String):
	if mode == move_mode:
		return
	var mode_func = move_modes[mode]
	if !(mode_func is Callable) or not mode_func:
		print("invalid move mode, aborting")
		return
	if stunned:
		await stun_ended
	move_mode = mode
	mode_func.call()
	if is_swapping_move_mode == true:
		print("delaying move mode swap to " + mode)
		await move_mode_swap_debounce_ended
	swapped_move_mode.emit()
	run_move_swap_debounce()

func run_move_swap_debounce():
	is_swapping_move_mode = true
	await get_tree().create_timer(0.2).timeout
	is_swapping_move_mode = false
	move_mode_swap_debounce_ended.emit()

func switch_act_mode(mode : String):
	if mode == act_mode:
		return
	var mode_func = act_modes[mode]
	if mode == "none":
		act_mode = "none"
		return
	elif !(mode_func is Callable) or not mode_func :
		print("invalid act mode, aborting")
		return
	if stunned:
		await stun_ended
	act_mode = mode
	mode_func.call()
	swapped_attack_mode.emit()

func death():
	switch_act_mode("none")
	switch_move_mode("death")

func activate_ability(ability : Ability):
	if ability.scene:
		var new_scene = ability.scene.instantiate()
		new_scene.caster = self
		if ability.is_parented == true:
			add_child(new_scene)
		else:
			get_parent().add_child(new_scene)
	SignalBus.abilityCast.emit(self,ability,attack_target)

func act_debounce():
	act_timer.start()
	await act_timer.timeout
	return true

func check_burst():
	for x in burst_thresholds:
		if hp.current_Health <= x:
			if triggered_burst_thresholds.find(x) < 0:
				triggered_burst_thresholds.append(x)
				burst_function.call(x)

func stun(duration : float):
	var current_velocity = velocity
	act_timer.paused = true
	move_timer.paused = true
	stunned = true
	await get_tree().create_timer(duration).timeout
	act_timer.paused = false
	move_timer.paused = false
	stunned = false
	velocity = current_velocity
	stun_ended.emit()

func build():
	if not hitbox:
		hitbox = Globals.find_by_type(self,HitboxComponent)
	if not hp:
		hp = Globals.find_by_type(self,HealthComponent)
	if not knockback:
		knockback = Globals.find_by_type(self,KnockbackComponent)
	if not navigation_agent:
		navigation_agent = Globals.find_by_type(self,NavigationAgent2D)
	navigation_agent.avoidance_enabled = true
	if not hp or not hitbox:
		print(name + "in scene " + get_parent().get_parent().name + " has been created without the required components and will be invulnerable (and might crash the game)")
	print("component searches complete on " + name)
	attack_target = State.currentPlayer
	hp.heartKilled.connect(death)
	act_timer = Timer.new()
	add_child(act_timer)
	act_timer.one_shot = true
	aggression_updated.emit()
	move_timer = Timer.new()
	add_child(move_timer)
	move_timer.one_shot = true
	move_timer.wait_time = move_frequency
	print("timers built on " + name)
	if !navigation_agent.is_connected("velocity_computed",_on_navigation_agent_2d_velocity_computed):
		navigation_agent.velocity_computed.connect(_on_navigation_agent_2d_velocity_computed)
	if !is_connected("aggression_updated",_on_aggression_updated):
		aggression_updated.connect(_on_aggression_updated)
	if !is_connected("move_frequency_updated",_on_move_frequency_updated):
		move_frequency_updated.connect(_on_move_frequency_updated)
	print("connections completed and assured")
	if hp:
		if !hp.is_connected("heartKilled",death):
			hp.heartKilled.connect(death)
		if !hp.is_connected("damaged",check_burst):
			hp.damaged.connect(check_burst)
	print("firing signal")
	attack_target = State.currentPlayer
	built.emit()
	
