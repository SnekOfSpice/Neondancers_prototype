extends Sprite

const BULLET_SCENE = preload("res://src/Weapons/Bullet.tscn")
export var magazine_size = 20
var current_magazine setget set_current_magazine, get_current_magazine
var is_reloading = false setget set_is_reloading, get_is_reloading

onready var fire_rate_timer = $FireRateTimer

func _ready() -> void:
	$Bullet.visible = false
	current_magazine = magazine_size

func _process(delta: float) -> void:
	if Input.is_action_pressed("right_trigger") && fire_rate_timer.time_left == 0 && !is_reloading:
		if current_magazine > 0:
			shoot()
			fire_rate_timer.start()
		else:
			reload()
	self.rotation = get_parent().get_parent().get_right_stick_input_vector2().angle()

func shoot() -> void:
	
	
	var bullet = BULLET_SCENE.instance()
	get_parent().get_parent().get_parent().add_child(bullet)
	bullet.position = Vector2(get_parent().get_parent().position.x + 102, get_parent().get_parent().position.y -62)
	# if the muzzle is left of the grip
	if get_parent().get_parent().get_gun_flipped_left():
		# flip the bullet direction
		bullet.set_bullet_speed(-bullet.get_bullet_speed())
		bullet.position = Vector2(get_parent().get_parent().position.x - 60, get_parent().get_parent().position.y -62)
		# flip_h didn't work
		# scale it for visually same result
		bullet.scale = Vector2(-1,1)
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
