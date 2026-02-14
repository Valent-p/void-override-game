class_name HealthComponent
extends Node

signal health_changed(current, max)
signal died

@export var max_health: float = 100.0
@onready var current_health: float = max_health

func damage(amount: float) -> void:
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0.0:
		died.emit()
		
func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
