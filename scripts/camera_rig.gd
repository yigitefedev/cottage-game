extends Node3D

@export var target: Node3D

@export var follow_speed := 6.0
@export var offset := Vector3(0, 8, 8)

@export var look_at_height := 1.0
@export var smooth_rotation := true
@export var rotation_speed := 8.0

@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	if target:
		global_position = target.global_position


func _physics_process(delta: float) -> void:
	if target == null:
		return

	var target_position := target.global_position
	var desired_position := target_position

	global_position = global_position.lerp(desired_position, follow_speed * delta)

	camera.position = offset

	var look_target := target.global_position + Vector3.UP * look_at_height

	if smooth_rotation:
		var direction := look_target - camera.global_position
		var desired_basis := Basis.looking_at(direction.normalized(), Vector3.UP)

		camera.global_basis = camera.global_basis.slerp(desired_basis, rotation_speed * delta)
	else:
		camera.look_at(look_target)
