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
@export var auto_level_speed: float = 5.0 # Speed to return to horizon when idle

@export_group("Visuals")
@export var bank_amount: float = 45.0 # Max roll angle when turning
@export var bank_speed: float = 5.0 # How fast visual banking catches up

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

var current_boost_fuel: float = 100.0

func _ready() -> void:
	assert(is_instance_valid(agent), "Must set the agent.")

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_handle_rotation(delta)
	
	# Reset input for next frame
	move_direction = Vector3.ZERO
	yaw_input = 0.0
	pitch_input = 0.0

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
	
	# Apply Yaw (Left/Right)
	# Apply Yaw (Left/Right)
	# We rotate the agent directly, but using a smoothed input approach would be better.
	# For now, let's apply direct physics rotation smoothed by `rotation_inertia`.
	
	# However, for "Galaxy on Fire" feel, the TURN itself should feel like it ramps up.
	# Let's apply rotation to the agent based on input.
	
	var target_pitch = pitch_input * pitch_speed * delta
	var target_yaw = -yaw_input * yaw_speed * delta
	
	# Apply rotation to the body
	agent.rotate_object_local(Vector3.RIGHT, target_pitch)
	agent.rotate_object_local(Vector3.UP, target_yaw)
	
	# --- AUTO-LEVEL ---
	# If no input is given, smoothly return the ship's roll to level with the horizon.
	if is_zero_approx(pitch_input) and is_zero_approx(yaw_input):
		var forward = -agent.global_transform.basis.z
		
		# Calculate Right vector (Forward x Up = -Z x Y = X)
		var right = forward.cross(Vector3.UP)
		
		# If looking straight up/down, cross product is zero, skip leveling to avoid quirks
		if right.length_squared() > 0.001:
			right = right.normalized()
			var up = right.cross(forward).normalized()
			
			var target_basis = Basis(right, up, -forward)
			
			# Ensure it's orthoonormalized to prevent set_quaternion errors
			target_basis = target_basis.orthonormalized()
			
			# Smoothly interpolate current basis to target basis (affects Roll primarily)
			# We use a slow speed so it feels like "gravity" pulling the wings level
			agent.global_transform.basis = agent.global_transform.basis.slerp(
				target_basis, auto_level_speed * delta
			)
	
	# 3. Visual Tilting (Banking)
	if is_instance_valid(mesh_to_tilt):
		# Calculate target roll based on YAW input (turning left = roll left)
		var target_roll = yaw_input * deg_to_rad(bank_amount)
		
		# Calculate target roll based on strafing (local X velocity)
		var local_velocity = agent.global_transform.basis.inverse() * agent.velocity
		var strafe_speed = local_velocity.x
		
		# Remap strafe speed to a tilt angle (e.g. +/- 15 degrees)
		# Moving Right (+X) -> Tilt Right (-Z usually)
		var strafe_tilt = -remap(
			strafe_speed, -max_speed, max_speed, -deg_to_rad(15.0), deg_to_rad(15.0)
		)
		
		var total_target_roll = target_roll + strafe_tilt
		
		# Smoothly interpolate current rotation to target
		var current_roll = mesh_to_tilt.rotation.z
		mesh_to_tilt.rotation.z = lerp_angle(
			current_roll, total_target_roll, bank_speed * delta
		)
