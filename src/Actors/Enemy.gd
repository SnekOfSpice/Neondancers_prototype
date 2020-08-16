extends KinematicBody2D

export var hit_points = 500
onready var speed = 40
onready var motion = Vector2.ZERO


func _ready() -> void:
	$ProgressBarHitPoints.max_value = hit_points

func _physics_process(delta: float) -> void:
	motion.x = speed
	motion = move_and_slide(motion, Vector2.UP)
	
func _process(delta: float) -> void:
	$ProgressBarHitPoints.value = hit_points
	if hit_points <= 0:
		die()

func die():
	queue_free()

func _on_TimerSwitchDirection_timeout() -> void:
	speed = -40 if speed == 40 else 40
	$TimerSwitchDirection.start()
