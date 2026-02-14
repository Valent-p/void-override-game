@tool
extends BTAction

## Finds the player and stores in blackboard

@export var output_var: StringName = &"target"


# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "Target Acquire"

func _tick(_delta: float) -> Status:
	var players = agent.get_tree().get_nodes_in_group("Player")
	if players.is_empty():
		players = agent.get_tree().get_nodes_in_group("player")
		
	if players.is_empty():
		return FAILURE
		
	blackboard.set_var(output_var, players[0])
	return SUCCESS

# Strings returned from this method are displayed as warnings in the behavior tree editor (requires @tool).
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	return warnings
