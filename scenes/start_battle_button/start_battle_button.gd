class_name StartBattleButton
extends Button

@export var game_state: GameState
@export var player_stats: PlayerStats
@export var arena_grid: UnitGrid
@export var round_manager: RoundManager

@onready var icon_texture: TextureRect = $Icon


func _ready() -> void:
	pressed.connect(_on_pressed)
	player_stats.changed.connect(_update)
	arena_grid.unit_grid_changed.connect(_update)
	game_state.changed.connect(_update)
	if round_manager != null:
		round_manager.game_over.connect(_update)
		round_manager.round_changed.connect(_on_round_changed)
	_update()


func _on_round_changed(_round: int) -> void:
	_update()


func _update() -> void:
	var units_used := arena_grid.get_all_units().size()
	var run_inactive := round_manager != null and not round_manager.is_run_active()
	
	disabled = run_inactive or game_state.is_battling() or units_used > player_stats.level or units_used == 0
	icon_texture.modulate.a = 0.5 if disabled else 1.0


func _on_pressed() -> void:
	if game_state.is_battling() or (round_manager != null and not round_manager.is_run_active()):
		return

	game_state.current_phase = GameState.Phase.BATTLE
	disabled = true
