extends KinematicBody2D

export var hit_points = 500
onready var speed = 100
onready var motion = Vector2.ZERO
onready var direction = false


func _ready() -> void:
	$ProgressBarHitPoints.max_value = hit_points

func _physics_process(delta: float) -> void:
	motion.x = directional_movement(speed, direction)
	motion = move_and_slide(motion, Vector2.UP)
	
func _process(delta: float) -> void:
	$ProgressBarHitPoints.value = hit_points
	if hit_points <= 0:
		die()

func die():
	queue_free()

func _on_TimerSwitchDirection_timeout() -> void:
	#speed = -40 if speed == 40 else 40
	$TimerSwitchDirection.start()

func directional_movement(speed_x, direction: bool) -> int:
	if direction:
		return speed_x
	else:
		return -speed_x

func switch_direction() -> void:
	direction = !direction

func _on_EdgeDetectorRight_body_exited(body: Node) -> void:
	if body is TileMap:
		switch_direction()


func _on_EdgeDetectorLeft_body_exited(body: Node) -> void:
	if body is TileMap:
		switch_direction()


func _on_WallDetectorRight_body_entered(body: Node) -> void:
	if body is TileMap:
		switch_direction()


func _on_WallDetectorLeft_body_entered(body: Node) -> void:
	if body is TileMap:
		switch_direction()
