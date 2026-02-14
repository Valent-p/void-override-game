@tool
extends BTAction

## Action to fire weapons


# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "Fire"


@export var target_var: StringName = &"target"

func _tick(_delta: float) -> Status:
	var target = blackboard.get_var(target_var)
	if not is_instance_valid(target):
		return FAILURE
		
	var target_pos = target.global_position if target is Node3D else target
	
	if agent.has_method("is_facing") and \
		not agent.is_facing(target_pos, 20.0):
		return RUNNING
		
	if agent.has_method("fire_weapon"):
		agent.fire_weapon()
		return SUCCESS # Fire and succeed, so sequence restarts or parallel continues
	return FAILURE

# Strings returned from this method are displayed as warnings in the behavior tree editor (requires @tool).
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	return warnings
