extends Area2D

export var bullet_speed = 1000 setget set_bullet_speed, get_bullet_speed
var motion

func _process(delta: float) -> void:
	motion = Vector2(1,0) * bullet_speed
	position += motion * delta

func _on_VisibilityNotifier2D_screen_exited() -> void:
	queue_free()

func set_bullet_speed(value: int) -> void:
	bullet_speed = value

func get_bullet_speed() -> int:
	return bullet_speed
