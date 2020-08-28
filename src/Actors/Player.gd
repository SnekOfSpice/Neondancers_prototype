extends KinematicBody2D

signal gun_spawned


# movement
var motion = Vector2.ZERO
export var walk_speed = 500
export var acceleration = 50
export var gravity = 10
export var jump_impulse = 750

export var dash_range_factor = 15000

# stamina
export var max_stamina = 100.0
var current_stamina = max_stamina
export var stamina_regen = 0.5
export var dash_cost = 17.5
export var aim_cost_per_frame = 0.8

var is_exhausted = false
var is_attacking = false

# gun
onready var gun_position_x = $GunRotating.position.x
onready var gun_position_y =  $GunRotating.position.y

export var gun_ads_speed = 7500.0

# melee
# placeholder in this script for now, will need to create melee scene later
var attack_damage = 200

# animation and perspective
var flip_idle = true
#onready var right_stick_input_vector2 = Vector2.ZERO setget set_right_stick_input_vector2, get_right_stick_input_vector2


func _ready() -> void:
	$AnimatedSprite.play("Idle")
	$DebugUI/IsExhaustedBar.max_value = $IsExhaustedTimer.wait_time
	$GunRotating.visible = false

# STATE MACHINE
#func _input(event: InputEvent) -> void:

func _physics_process(delta: float) -> void:
	apply_gravity()

	if current_stamina < max_stamina && !is_exhausted:
		current_stamina += stamina_regen
	if current_stamina > max_stamina:
		current_stamina = max_stamina
	
	if $DashTimer.time_left > 0:
		$ParticlesDash.emitting = true
		$ParticlesDash.rotation = AutoLoad.get_right_stick_input_vector2().angle()
	else:
		$ParticlesDash.emitting = false
	
	
	if (right_stick_input()
		&& !Input.is_action_pressed("left_trigger")
		):
		#Input.is_action_just_pressed("dash_debug"))):
			$GunRotating.visible = false
			var input_vector = Vector2.ZERO
			#input_vector.x = Input.get_action_strength("right_stick_right") - Input.get_action_strength("right_stick_left")
			#input_vector.y = Input.get_action_strength("right_stick_down") - Input.get_action_strength("right_stick_up")
			input_vector.x = Input.get_joy_axis(0, JOY_AXIS_2)
			input_vector.y = Input.get_joy_axis(0 ,JOY_AXIS_3)
			input_vector = input_vector.normalized()
			AutoLoad.right_stick_input_vector2 = input_vector
			dash()
	elif (is_aiming()):
		$GunRotating.visible = false
		var input_vector = Vector2.ZERO
		#input_vector.x = Input.get_action_strength("right_stick_right") - Input.get_action_strength("right_stick_left")
		#input_vector.y = Input.get_action_strength("right_stick_down") - Input.get_action_strength("right_stick_up")
		input_vector.x = Input.get_joy_axis(0, JOY_AXIS_2)
		input_vector.y = Input.get_joy_axis(0 ,JOY_AXIS_3)
		input_vector = input_vector.normalized()
		AutoLoad.right_stick_input_vector2 = input_vector
	elif Input.is_action_pressed("move_left"):
		if !is_attacking:
			$AnimatedSprite.play("Run")
		$GunRotating.visible = false
		#$Gun.flip_h = true
		# + 55 is cosmetic offset
		#$Gun.position = Vector2(-gun_position_x + 55, gun_position_y)
		$GunRotating.position = Vector2(-gun_position_x * AutoLoad.right_stick_input_vector2.x, gun_position_y)
		$AnimatedSprite.flip_h = true
		motion.x = (-walk_speed / 2) if is_attacking else -walk_speed
		flip_idle = true
	elif Input.is_action_pressed("move_right"):
		if !is_attacking:
			$AnimatedSprite.play("Run")
		$GunRotating.visible = false
		#$Gun.flip_h = false
		#$Gun.position = Vector2(gun_position_x, gun_position_y)
		$GunRotating.position = Vector2(gun_position_x, gun_position_y)
		$AnimatedSprite.flip_h = false
		motion.x = (walk_speed / 2) if is_attacking else walk_speed
		flip_idle = false
	else:
		$GunRotating.visible = false
		motion.x = 0
		if flip_idle:
			$AnimatedSprite.flip_h = true
		else:
			$GunRotating.visible = false
			$AnimatedSprite.flip_h = false
		if !is_attacking:
			$AnimatedSprite.play("Idle")
	#if motion.x > (walk_speed * dash_range_factor) / 2:
		#$AnimatedSprite.play("dash")
	
	if Input.is_action_pressed("left_trigger") && !(current_stamina < aim_cost_per_frame) && !is_exhausted:
		# && !is_on_floor() aming always takes stamina? -> playtest
		$GunRotating.visible = true
		if Input.is_action_just_pressed("left_trigger"):
			$GunRotating.get_node("Particles2DSpawn").restart()
		#$GunRotating.get_node("SpawnTimer").start()
		
		if Input.is_action_just_pressed("left_trigger"):
			#$GunRotating.play("default")
			if motion.x > 0:
				AutoLoad.set_right_stick_input_vector2(Vector2(1,0))
			elif motion.y < 0:
				AutoLoad.set_right_stick_input_vector2(Vector2(-1,0))
		$AnimatedSprite.rotation = 0
		$AnimatedSprite.speed_scale = 0.5
		motion.x /= 5
		motion.y /= 3
		if !is_on_floor():
			current_stamina -= aim_cost_per_frame
			if (current_stamina < aim_cost_per_frame):
				make_exhausted()
	
	if Input.is_action_just_pressed("a_button") && is_on_floor():
		motion.y = -jump_impulse
	
	melee_if_input()
	
	motion = move_and_slide(motion, Vector2.UP)
	
	 
	if is_on_floor():
		$AnimatedSprite.rotation = 0
	
	if out_of_stamina():
		make_exhausted()
	
	# gamepad map
	# 1 - bumper
	# 2 - trigger
	# 3 - stick press
	
	
	# works maybe??
	#if !is_on_floor() && motion.y > 25:
	#	$AnimationPlayer.play("rotate_up")
	
	if Input.is_action_pressed("move_right"):
		get_node("AttackArea").set_scale(Vector2(1, 1))
	elif Input.is_action_pressed("move_left"): 
		get_node("AttackArea").set_scale(Vector2(-1, 1))


func melee_if_input():
	if Input.is_action_just_pressed("x_button"):
		is_attacking = true
		$AnimatedSprite.play("Attack")
		$AttackArea/CollisionShape2D.disabled = false
		# implement slowed movement while attacking

func _process(delta: float) -> void:
	# https://godotengine.org/qa/62408/make-the-camera-look-at-an-object
	if Input.is_action_pressed("left_trigger"):
		#$Camera2D.offset = AutoLoad.right_stick_input_vector2 * 200
		$Camera2D.set_global_position(lerp(get_global_position(), get_global_position() + (AutoLoad.right_stick_input_vector2.normalized()), delta*gun_ads_speed))
	elif Input.is_action_just_released("left_trigger"):
		#$Camera2D.offset = Vector2.ZERO
		$Camera2D.set_global_position(lerp(get_global_position(), get_global_position() - (AutoLoad.right_stick_input_vector2.normalized()), delta*gun_ads_speed))
	else:
		$Camera2D.set_global_position(lerp(get_global_position(), get_global_position(),delta*gun_ads_speed))
	
	# set all the DebugUI info
	update_debug_ui()
	

func dash() -> void:
	is_attacking = false
	if current_stamina < dash_cost:
		make_exhausted()
	else:
		#print_debug("dashing")
		var move = AutoLoad.right_stick_input_vector2
		current_stamina -= dash_cost
		$DashTimer.start()
		#motion *= dash_range_factor
		$AnimatedSprite.play("Dash")
		
		# boosts the dash if it is less than 90 degrees apart from itself, mirrored on a Vector2.UP
		# or is just straight up and can't be mirrored I think?
		# 180° = -1, 90° = 0, 0° = 1
		# https://docs.godotengine.org/en/stable/tutorials/math/vector_math.html
		if (move.y < 0 && (move.dot(move.bounce(Vector2.UP)) > 0)) || move == Vector2.UP:
			print("dash enhanced")
			move.y *= 1.25
		move *= dash_range_factor
		motion = move_and_slide(move)
		# remove inertia from dashing to remain pin-point
		motion = Vector2.ZERO
	

func out_of_stamina() -> bool:
	return current_stamina <= 0

func _on_DashTimer_timeout() -> void:
	motion.x = walk_speed

func make_exhausted() -> void:
	is_exhausted = true
	current_stamina = 0
	if !$IsExhaustedTimer.time_left > 0:
		$IsExhaustedTimer.start()

func _on_IsExhaustedTimer_timeout() -> void:
	is_exhausted = false


func _on_DebugTimer_timeout() -> void:
	#print_debug("current_stamina: ", current_stamina)
	#print_debug("is_exhausted: ", is_exhausted)
	#print_debug("exhausted time left: ", $IsExhaustedTimer.time_left)
	$DebugTimer.start()

func right_stick_input() -> bool:
	return (Input.is_action_just_pressed("right_stick_down") || Input.is_action_just_pressed("right_stick_left") || Input.is_action_just_pressed("right_stick_right") || Input.is_action_just_pressed("right_stick_up"))

func is_aiming() -> bool:
	return right_stick_input() && Input.is_action_pressed("left_trigger")






func apply_gravity() -> void:
	# faster acceleration at start of fall with upper limit
	if motion.y < 100:
		motion.y += gravity * 5
	elif motion.y < 250:
		motion.y += gravity * 2
	elif motion.y < 500:
		motion.y += gravity * 1.5
	elif motion.y > 2000:
		motion.y = 2000
	else:
		motion.y += gravity



func update_debug_ui() -> void:
	$DebugUI.get_node("LabelCurrentStamina").text = "current_stamina: %s" % current_stamina
	$DebugUI.get_node("LabelIsExhausted").text = "is_exhausted: %s" % is_exhausted
	$DebugUI.get_node("LabelExhaustedTimeLeft").text = "IsExhaustedTimer.time_left: %s" % $IsExhaustedTimer.time_left
	$DebugUI.get_node("LabelFPS").text = "FPS: %s" % Engine.get_frames_per_second()
	$DebugUI.get_node("StaminaBar").value = current_stamina
	if is_exhausted:
		$DebugUI.get_node("IsExhaustedBar").max_value = $IsExhaustedTimer.wait_time
		$DebugUI.get_node("IsExhaustedBar").visible = true
		$DebugUI.get_node("IsExhaustedBar").value = $IsExhaustedTimer.time_left
	else:
		$DebugUI.get_node("IsExhaustedBar").visible = false
	
	$DebugUI.get_node("LabelCurrentMagazine").text = "current_magazine: %s" % $GunRotating.get_current_magazine()
	$DebugUI.get_node("LabelIsReloading").text = "is_reloading: %s" % $GunRotating.get_is_reloading()
	$DebugUI.get_node("LabelReloadTimeLeft").text = "ReloadTimer.time_left: %s" % $GunRotating.get_node("ReloadTimer").time_left
	
	$DebugUI.get_node("LabelRightStickInput").text = "AutoLoad.right_stick_input_vector2: %s" % AutoLoad.right_stick_input_vector2
	$DebugUI.get_node("LabelGunRotatingVisible").text = "GunRotating.visible: %s" % $GunRotating.visible
	$DebugUI.get_node("LabelMuzzlePosition").text = "AutoLoad.muzzle_position: %s" % AutoLoad.muzzle_position
	
	$DebugUI/LabelMotion.text = "Motion: %s" % motion


func _on_AnimatedSprite_animation_finished() -> void:
	if $AnimatedSprite.animation == "Attack":
		$AttackArea/CollisionShape2D.disabled = true
		is_attacking = false


func _on_AttackArea_body_entered(body: Node) -> void:
	if body.get_collision_layer_bit(2):
		body.hit_points -= attack_damage
