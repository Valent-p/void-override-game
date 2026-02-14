@tool
extends BTAction

## Moves the agent towards a target but stops at 
## a specific distance

@export var target_var: StringName = &"target"
@export var stop_distance: float = 30.0

func _generate_name() -> String:
	return "Follow Target (Dist: %s)" % stop_distance

func _tick(_delta: float) -> Status:
	var target = blackboard.get_var(target_var)
	if not is_instance_valid(target):
		return FAILURE
		
	var target_pos = target.global_position if target is Node3D else target
	
	if agent.has_method("move_towards"):
		agent.move_towards(target_pos, stop_distance)
		return RUNNING
		
	return FAILURE

# Strings returned from this method are displayed as warnings in the behavior tree editor (requires @tool).
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	return warnings
