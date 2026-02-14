@tool
extends BTAction
## Makes the agent rotate towards a target position or object

@export var target_var: StringName = &"target" # Value in blackboard

# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "Face Target"

func _tick(_delta: float) -> Status:
	var target = blackboard.get_var(target_var)
	if not is_instance_valid(target):
		return FAILURE
		
	var target_pos: Vector3 # For enemies, we'll calculate the direction and set it.
	if target is Node3D:
		target_pos = target.global_position
	else:
		target_pos = target
	var char_body = agent as CharacterBody3D
	
	if char_body.has_method("face_target"):
		char_body.face_target(target_pos)
		
	return RUNNING

# Strings returned from this method are displayed as warnings in the behavior tree editor (requires @tool).
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	return warnings
