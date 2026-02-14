class_name CameraLagComponent
extends Node
## Adds "Action Camera" feel with lag and FOV effects

@export_group("References")
@export var target_node: Node3D
@export var camera: Camera3D

@export_group("Settings")
@export var position_lag_speed: float = 10.0
@export var rotation_lag_speed: float = 8.0
@export var fov_base: float = 75.0
@export var fov_max: float = 90.0
@export var fov_speed: float = 5.0

@export_group("Shake Settings")
@export var shake_decay: float = 5.0

# Offset is calculated on ready
var _offset: Vector3
var _shake_strength: float = 0.0

func _ready() -> void:
	add_to_group("camera_shake")
	if not is_instance_valid(target_node):
		# Try to find parent if not set
		target_node = get_parent()
		
	if not is_instance_valid(camera):
		# Check if parent is camera, or siblings
		if get_parent() is Camera3D:
			camera = get_parent()
	
	if is_instance_valid(target_node) and is_instance_valid(camera):
		# Detach camera to top level so it doesn't move with parent automatically
		camera.top_level = true
		# Calculate initial offset in local space of the target
		_offset = target_node.global_transform.basis.inverse() * (
			camera.global_position - target_node.global_position
		)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target_node) or not is_instance_valid(camera):
		return
		
	# 1. Position Lag
	var desired_position = target_node.global_transform * _offset
	
	# Apply Shake
	_shake_strength = lerp(_shake_strength, 0.0, shake_decay * delta)
	var shake_offset = Vector3(
		randf_range(-_shake_strength, _shake_strength),
		randf_range(-_shake_strength, _shake_strength),
		randf_range(-_shake_strength, _shake_strength)
	)
	
	camera.global_position = camera.global_position.lerp(
		desired_position + shake_offset, position_lag_speed * delta
	)
	
	# 2. Rotation Lag
	camera.global_rotation.x = lerp_angle(
		camera.global_rotation.x, target_node.global_rotation.x, rotation_lag_speed * delta
	)
	camera.global_rotation.y = lerp_angle(
		camera.global_rotation.y, target_node.global_rotation.y, rotation_lag_speed * delta
	)
	camera.global_rotation.z = lerp_angle(
		camera.global_rotation.z, target_node.global_rotation.z, rotation_lag_speed * delta
	)
	
	# 3. Dynamic FOV
	if target_node is CharacterBody3D:
		var speed_fraction = clamp((target_node.velocity.length() - 10.0) / 50.0, 0.0, 1.0)
		var target_fov = lerp(fov_base, fov_max + 10.0, speed_fraction)
		camera.fov = lerp(camera.fov, target_fov, fov_speed * delta)

func add_shake(strength: float) -> void:
	_shake_strength += strength
