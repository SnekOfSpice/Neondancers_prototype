extends Node

onready var right_stick_input_vector2 = Vector2(1,0) setget set_right_stick_input_vector2, get_right_stick_input_vector2 
onready var muzzle_position = Vector2.ZERO setget set_muzzle_position, get_muzzle_position

func set_right_stick_input_vector2(value: Vector2) -> void:
	right_stick_input_vector2 = value

func get_right_stick_input_vector2() -> Vector2:
	return right_stick_input_vector2

func set_muzzle_position(value: Vector2) -> void:
	muzzle_position = value

func get_muzzle_position() -> Vector2:
	return muzzle_position
