class_name MovementComponent
extends Node
## Control logic for the spaceship

@export_group("References")
@export var agent: CharacterBody3D
@export var mesh_to_tilt: Node3D

@export_group("Movement Settings")
@export var max_speed: float = 25.0
@export var acceleration: float = 50.0
@export var friction: float = 60.0

@export_group("Visuals")
@export var tilt_amount: float = 15.0 # Degrees
@export var tilt_speed: float = 5.0

## Set this every frame to control movement
var move_direction: Vector3 = Vector3.ZERO

func _ready() -> void:
	assert(is_instance_valid(agent), "Must set the agent.")

func _physics_process(delta: float) -> void:
	# 1. Apply Movement (Acceleration / Friction)
	var target_velocity_vector = move_direction * max_speed
	
	if move_direction.length_squared() > 0.001:
		# Accelerate towards target
		agent.velocity = agent.velocity.move_toward(target_velocity_vector, acceleration * delta)
	else:
		# Decelerate (Friction)
		agent.velocity = agent.velocity.move_toward(Vector3.ZERO, friction * delta)
		
	# 2. Solid Ground Constraint - REMOVED for 3D Flight
	# agent.velocity.y = 0.0
	# agent.global_position.y = 0.0
	
	agent.move_and_slide()
	
	# 3. Visual Tilting (Banking)
	if is_instance_valid(mesh_to_tilt):
		_handle_tilt(delta)

	# Reset input for next frame
	move_direction = Vector3.ZERO

func _handle_tilt(delta: float) -> void:
	# Calculate local X velocity (strafing speed) relative to the ship's facing
	# transform.basis.x is the local "Right" vector
	var local_velocity = agent.global_transform.basis.inverse() * agent.velocity
	var strafe_speed = local_velocity.x
	
	# Calculate target tilt (roll)
	# If moving right (+x), we want to tilt right (negative Z rotation usually, depending on setup)
	# Let's try: move right -> tilt right (negative Z)
	var target_tilt = -remap(strafe_speed, -max_speed, max_speed, -tilt_amount, tilt_amount)
	
	# Convert degrees to radians
	var target_rot_z = deg_to_rad(target_tilt)
	
	# Smoothly interpolate current rotation to target
	mesh_to_tilt.rotation.z = lerp_angle(mesh_to_tilt.rotation.z, target_rot_z, tilt_speed * delta)
