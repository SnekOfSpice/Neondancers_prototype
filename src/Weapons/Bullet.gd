extends Area2D

export onready var bullet_speed = 1000 setget set_bullet_speed, get_bullet_speed
var bullet_speed_vector setget set_bullet_speed_vector
var bullet_direction setget set_bullet_direction

var damage = 10

func _ready() -> void:
	bullet_speed_vector = Vector2(bullet_speed, bullet_speed)
	bullet_direction = AutoLoad.right_stick_input_vector2

func _process(delta: float) -> void:
	#motion = Vector2(1,0) * bullet_speed
	#bullet_speed_vector = AutoLoad.right_stick_input_vector2 * bullet_speed
	self.position += bullet_direction * (bullet_speed_vector / 100)#/ 500)
	#motion = Vector2(1,0) * AutoLoad.right_stick_input_vector2 * bullet_speed
	#motion *= bullet_speed
	#position += motion * delta

func _on_VisibilityNotifier2D_screen_exited() -> void:
	queue_free()

func set_bullet_speed(value: int) -> void:
	bullet_speed = value

func get_bullet_speed() -> int:
	return bullet_speed

func set_bullet_speed_vector(value: Vector2) -> void:
	bullet_speed_vector = value

func set_bullet_direction(value: Vector2) -> void:
	bullet_direction = value


func _on_Bullet_body_entered(body: Node) -> void:
	if body.get_collision_layer_bit(2):
		body.hit_points -= damage
		self.queue_free()
	if body is TileMap:
		self.queue_free()
