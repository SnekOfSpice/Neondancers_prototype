extends AnimatedSprite

const BULLET_SCENE = preload("res://src/Weapons/Bullet.tscn")
export var magazine_size = 20
var current_magazine setget set_current_magazine, get_current_magazine
var is_reloading = false setget set_is_reloading, get_is_reloading

onready var fire_rate_timer = $FireRateTimer

func _ready() -> void:
	$Bullet.visible = false
	current_magazine = magazine_size

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("b_button") && !is_reloading && current_magazine < magazine_size:
		reload()
	if Input.is_action_pressed("right_trigger") && fire_rate_timer.time_left == 0 && !is_reloading:
		if current_magazine > 0:
			shoot()
			fire_rate_timer.start()
		else:
			reload()
	
	# rotation & orientation
	var angle = AutoLoad.get_right_stick_input_vector2().angle()
	self.rotation = angle
	if angle < 270 && angle > 90:
		flip_h = true
	else:
		flip_h = false
	var point = Vector2(get_parent().get_node("Position2DGunOrigin").position)
	position = point + Vector2(cos(angle), sin(angle)) * (-100 if (angle < 90 && angle > 270) else 100)
	position = point + (position - point).rotated(angle)
	# https://godotengine.org/qa/50695/rotate-object-around-origin
	AutoLoad.set_muzzle_position($Position2DMuzzle.global_position)
	look_at($Position2DMuzzle.global_position)


func shoot() -> void:
	if visible:
		var bullet = BULLET_SCENE.instance()
		get_parent().get_parent().get_parent().add_child(bullet)
		bullet.set_bullet_direction(AutoLoad.right_stick_input_vector2)
		bullet.position = AutoLoad.get_muzzle_position()
		bullet.rotation = AutoLoad.right_stick_input_vector2.angle()
		current_magazine -= 1

func reload() -> void:
	is_reloading = true
	$ReloadTimer.start()



func _on_ReloadTimer_timeout() -> void:
	is_reloading = false
	current_magazine = magazine_size

func set_current_magazine(value: int) -> void:
	current_magazine = value

func get_current_magazine() -> int:
	return current_magazine

func set_is_reloading(value: bool) -> void:
	is_reloading = value

func get_is_reloading() -> bool:
	return is_reloading


func _on_SpawnTimer_timeout() -> void:
	$Particles2DSpawn.visible = false
