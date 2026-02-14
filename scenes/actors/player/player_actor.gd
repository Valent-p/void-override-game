extends CharacterBody3D

@export var max_health: float = 100.0

@onready var game_hud: GameHUD = $GameHUD

func _ready() -> void:
	if game_hud:
		game_hud.initialize(self)
