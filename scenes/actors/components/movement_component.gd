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

@export_group("Rotation Settings")
@export var pitch_speed: float = 2.5 * 10
@export var yaw_speed: float = 2.5 * 10
@export var roll_speed: float = 2.5 * 10
@export var rotation_inertia: float = 4.0 # Lower is heavier, higher is snappier (Lerp weight)
@export var auto_level_speed: float = 3.0 # Speed to return to horizon when idle

@export_group("Visuals")
@export var bank_amount: float = 45.0 # Max roll angle when turning
@export var bank_speed: float = 5.0 # How fast visual banking catches up
@export var thruster_particles: Array[GPUParticles3D] = []

@export_group("Boost")
@export var boost_multiplier: float = 2.5
@export var max_boost_fuel: float = 100.0
@export var boost_drain_rate: float = 20.0 # Fuel per second
@export var boost_refill_rate: float = 10.0 # Fuel per second

signal boost_changed(current: float, max: float)

## Set this every frame to control movement
var move_direction: Vector3 = Vector3.ZERO
var yaw_input: float = 0.0
var pitch_input: float = 0.0
var is_boosting: bool = false # Set by input

# Internal state for rotation smoothing
var _pitch_velocity: float = 0.0
var _yaw_velocity: float = 0.0

var current_boost_fuel: float = 100.0

func _ready() -> void:
	assert(is_instance_valid(agent), "Must set the agent.")
	add_to_group("movement_components")
	
	# Initial particles state
	_update_thrusters(0.0, false)

## Helper for AI to turn towards a global position
func steer_towards(target_pos: Vector3) -> void:
	var local_pos = agent.to_local(target_pos)
	var local_dir = local_pos.normalized()
	
	# Stronger Steering with "Behind" stability
	# atan2(x, -z) gives angle from forward
	var target_yaw = atan2(local_dir.x, -local_dir.z)
	
	# If target is directly behind (near PI), avoid flickering between PI and -PI
	if abs(target_yaw) > 3.0:
		target_yaw = PI # Force a consistent turn direction
		
	yaw_input = clamp(target_yaw * 3.0, -1.0, 1.0)
	
	# Vertical (Pitch)
	var target_pitch = atan2(local_dir.y, Vector2(local_dir.x, local_dir.z).length())
	pitch_input = -clamp(target_pitch * 3.0, -1.0, 1.0)

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_rotation(delta)
	
	# Update thrusters based on forward movement
	var forward_amount = clamp(-move_direction.z, 0.0, 1.0)
	_update_thrusters(forward_amount, is_boosting and current_boost_fuel > 0)
	
	# Reset input for next frame
	move_direction = Vector3.ZERO
	yaw_input = 0.0
	pitch_input = 0.0

func _update_thrusters(amount: float, boosting: bool) -> void:
	for p in thruster_particles:
		if not is_instance_valid(p): continue
		
		var target_ratio = amount
		if boosting:
			target_ratio = 1.0
			
		p.amount_ratio = lerp(p.amount_ratio, target_ratio, 0.1)
		
		# Enable/Disable based on activity to save performance
		p.emitting = p.amount_ratio > 0.01

func _handle_movement(delta: float) -> void:
	# 1. Apply Movement (Acceleration / Friction)
	var final_speed = max_speed
	
	# Fuel Logic
	if is_boosting and current_boost_fuel > 0:
		final_speed *= boost_multiplier
		current_boost_fuel = max(0.0, current_boost_fuel - boost_drain_rate * delta)
	else:
		current_boost_fuel = min(max_boost_fuel, current_boost_fuel + boost_refill_rate * delta)
		
	# Emit signal
	boost_changed.emit(current_boost_fuel, max_boost_fuel)
	
	var target_velocity_vector = move_direction * final_speed
	
	if move_direction.length_squared() > 0.001:
		# Accelerate towards target
		agent.velocity = agent.velocity.move_toward(target_velocity_vector, acceleration * delta)
	else:
		# Decelerate (Friction)
		agent.velocity = agent.velocity.move_toward(Vector3.ZERO, friction * delta)
		
	agent.move_and_slide()

func _handle_rotation(delta: float) -> void:
	if not is_instance_valid(agent): return
	
	# Smooth Inputs
	_pitch_velocity = lerp(_pitch_velocity, pitch_input * pitch_speed, rotation_inertia * delta)
	_yaw_velocity = lerp(_yaw_velocity, yaw_input * yaw_speed, rotation_inertia * delta)
	
	if abs(_pitch_velocity) < 0.01: _pitch_velocity = 0.0
	if abs(_yaw_velocity) < 0.01: _yaw_velocity = 0.0

	# CRITICAL: Stable Arcade Flight Math
	# 1. Pitch locally (around ship's wings)
	agent.rotate_object_local(Vector3.RIGHT, _pitch_velocity * delta)
	
	# 2. Yaw GLOBALLY (around world UP) to prevent gimbal lock
	agent.rotate(Vector3.UP, -_yaw_velocity * delta)
	
	# 3. Always Auto-Level Roll (Keep wings parallel to horizon)
	var forward = -agent.global_transform.basis.z
	var right = forward.cross(Vector3.UP)
	
	if right.length_squared() > 0.001:
		right = right.normalized()
		var up = right.cross(forward).normalized()
		var target_basis = Basis(right, up, -forward).orthonormalized()
		
		# Slowly lerp the entire basis towards a level state
		agent.global_transform.basis = agent.global_transform.basis.slerp(
			target_basis, auto_level_speed * delta
		)
	
	# 4. Visual Tilting (Banking)
	if is_instance_valid(mesh_to_tilt):
		# Calculate target roll based on YAW input (turning left = roll left)
		var target_bank = yaw_input * deg_to_rad(bank_amount)
		
		# Calculate target roll based on strafing
		var local_velocity = agent.global_transform.basis.inverse() * agent.velocity
		var strafe_speed = local_velocity.x
		var strafe_tilt = -remap(
			strafe_speed, -max_speed, max_speed, -deg_to_rad(15.0), deg_to_rad(15.0)
		)
		
		var total_target_roll = target_bank + strafe_tilt
		
		# Smoothly interpolate current rotation to target
		mesh_to_tilt.rotation.z = lerp_angle(
			mesh_to_tilt.rotation.z, total_target_roll, bank_speed * delta
		)
