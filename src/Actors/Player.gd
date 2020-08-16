extends KinematicBody2D

signal gun_spawned


# movement
var motion = Vector2.ZERO
export var walk_speed = 500
export var acceleration = 50
export var gravity = 10
export var jump_impulse = 30

export var dash_range_factor = 10000

# stamina
export var max_stamina = 100.0
var current_stamina = max_stamina
export var stamina_regen = 0.5
export var dash_cost = 17.5
export var aim_cost_per_frame = 0.8

var is_exhausted = false

# gun
onready var gun_position_x = $GunRotating.position.x
onready var gun_position_y =  $GunRotating.position.y

export var gun_ads_speed = 7500.0

# animation and perspective
var flip_idle = true
#onready var right_stick_input_vector2 = Vector2.ZERO setget set_right_stick_input_vector2, get_right_stick_input_vector2


func _ready() -> void:
	$AnimatedSprite.play("Idle")
	$DebugUI/IsExhaustedBar.max_value = $IsExhaustedTimer.wait_time
	$GunRotating.visible = false

func _physics_process(delta: float) -> void:
	# apply gravity
	if motion.y < 250:
		motion.y += gravity * 2
	elif motion.y < 500:
		motion.y += gravity * 1.5
	elif motion.y > 2000:
		motion.y = 2000
	else:
		motion.y += gravity

	if current_stamina < max_stamina && !is_exhausted:
		current_stamina += stamina_regen
	if current_stamina > max_stamina:
		current_stamina = max_stamina
	
	if $DashTimer.time_left > 0:
		$AnimatedSprite.play("Dash")
	
	
	if (right_stick_input()
		&& $DashOnCooldownTimer.time_left == 0
		&& !Input.is_action_pressed("left_trigger")
		):
		#Input.is_action_just_pressed("dash_debug"))):
			$GunRotating.visible = false
			var input_vector = Vector2.ZERO
			input_vector.x = Input.get_action_strength("right_stick_right") - Input.get_action_strength("right_stick_left")
			input_vector.y = Input.get_action_strength("right_stick_down") - Input.get_action_strength("right_stick_up")
			input_vector = input_vector.normalized()
			AutoLoad.right_stick_input_vector2 = input_vector
			dash(input_vector)
	elif (is_aiming()):
		$GunRotating.visible = false
		var input_vector = Vector2.ZERO
		input_vector.x = Input.get_action_strength("right_stick_right") - Input.get_action_strength("right_stick_left")
		input_vector.y = Input.get_action_strength("right_stick_down") - Input.get_action_strength("right_stick_up")
		input_vector = input_vector.normalized()
		AutoLoad.right_stick_input_vector2 = input_vector
	elif Input.is_action_pressed("move_left"):
		$GunRotating.visible = false
		#$Gun.flip_h = true
		# + 55 is cosmetic offset
		#$Gun.position = Vector2(-gun_position_x + 55, gun_position_y)
		$GunRotating.position = Vector2(-gun_position_x * AutoLoad.right_stick_input_vector2.x, gun_position_y)
		$AnimatedSprite.flip_h = true
		$AnimatedSprite.play("Run")
		motion.x = -walk_speed
		flip_idle = true
	elif Input.is_action_pressed("move_right"):
		$GunRotating.visible = false
		#$Gun.flip_h = false
		#$Gun.position = Vector2(gun_position_x, gun_position_y)
		$GunRotating.position = Vector2(gun_position_x, gun_position_y)
		$AnimatedSprite.flip_h = false
		$AnimatedSprite.play("Run")
		motion.x = walk_speed
		flip_idle = false
	elif Input.is_action_pressed("jump") && is_on_floor():
		$GunRotating.visible = false
		motion.y = jump_impulse
		motion = move_and_slide(motion, Vector2.UP)
	else:
		$GunRotating.visible = false
		motion.x = 0
		if flip_idle:
			$AnimatedSprite.flip_h = true
		else:
			$GunRotating.visible = false
			$AnimatedSprite.flip_h = false
		$AnimatedSprite.play("Idle")
	if motion.x > (walk_speed * dash_range_factor) / 2:
		$AnimatedSprite.play("dash")
	
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

func dash(input_vector: Vector2) -> void:
	if current_stamina < dash_cost:
		print_debug("too low stamina to dash")
	else:
		print_debug("dashing")
		current_stamina -= dash_cost
		$DashTimer.start()
		#motion *= dash_range_factor
		$AnimatedSprite.play("Dash")
	
		# will be obsolete bc dash will be one swoosh effect
		#if motion.x > 0:
		#	$AnimatedSprite.flip_h = false
		#else:
		#	$AnimatedSprite.flip_h = true
	
		# rotate the dash anim to the direction of the dash
		$AnimatedSprite.rotation = input_vector.angle()
	
		var move = input_vector * dash_range_factor
		motion = move_and_slide(move)
		# remove inertia from dashing to remain pin-point
		motion = Vector2.ZERO
	

func out_of_stamina() -> bool:
	return current_stamina <= 0

func _on_DashTimer_timeout() -> void:
	motion.x = walk_speed
	$DashOnCooldownTimer.start()

func make_exhausted() -> void:
	is_exhausted = true
	$IsExhaustedTimer.start()

func _on_IsExhaustedTimer_timeout() -> void:
	is_exhausted = false


func _on_DebugTimer_timeout() -> void:
	print_debug("current_stamina: ", current_stamina)
	print_debug("is_exhausted: ", is_exhausted)
	print_debug("exhausted time left: ", $IsExhaustedTimer.time_left)
	$DebugTimer.start()

func right_stick_input() -> bool:
	return (Input.is_action_just_pressed("right_stick_down") || Input.is_action_just_pressed("right_stick_left") || Input.is_action_just_pressed("right_stick_right") || Input.is_action_just_pressed("right_stick_up"))

func is_aiming() -> bool:
	return right_stick_input() && Input.is_action_pressed("left_trigger")
	
