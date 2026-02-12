class_name PlayerInputComponent
extends Node
## Sends user input to the movement component

@export var movement_component: MovementComponent
@export var mouse_sensitivity: float = 0.002

# Speed modifier for moving backwards
const BACKWARD_SPEED_MODIFIER = 0.6

func _ready() -> void:
	assert(is_instance_valid(movement_component), "Must set the movement component.")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	# Handle Mouse Rotation
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if is_instance_valid(movement_component.agent):
			# Pitch (Nose Up/Down)
			# We accumulate input or just pass the relative value
			# Since we want "steering", we pass the relative motion to the movement component
			# The movement component will apply it over time (or directly, depending on logic)
			
			# Adaptation: We can treat mouse relative as an accumulation to the input for this frame.
			movement_component.pitch_input += event.relative.y * mouse_sensitivity
			movement_component.yaw_input += event.relative.x * mouse_sensitivity
			
	# Toggle Mouse Capture with ESC
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(_delta: float) -> void:
	_handle_movement()

func _handle_movement() -> void:
	# Get vector from Input Map
	# I.e. "move_left", "move_right", "move_forward", "move_backward"
	var input_vector = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	)
	
	# Create 3D direction (x, 0, y)
	var direction = Vector3(input_vector.x, 0, input_vector.y)
	
	# Apply directional modifiers
	if direction.z > 0: # Moving backward
		direction *= BACKWARD_SPEED_MODIFIER
		
	# Convert to world space relative to the agent's facing direction
	# We use the agent's basis to transform the local direction to world direction
	if is_instance_valid(movement_component.agent):
		var world_direction = movement_component.agent.global_transform.basis * direction
		# NOTE: We DO NOT flatten Y anymore for 6DOF flight. 
		# If the ship is looking up, "Forward" means moving Up.
		
		# Send to movement component
		movement_component.move_direction = world_direction
