extends Node
class_name RoundManager

signal round_changed(round: int)
signal round_rewarded(round: int, gold: int)
signal game_over

@export var starting_gold: int = 5
@export var base_enemy_count: int = 1
@export var reward_base: int = 2
@export var reward_growth: float = 1.35

@export var player_stats: PlayerStats
@export var round_label: Label
@export var game_over_panel: Control
@export var enemy_spawn_points_root: Node2D

var current_round: int = 1
var run_active: bool = true


func _ready() -> void:
	start_new_run()


func start_new_run() -> void:
	current_round = 1
	run_active = true

	if player_stats != null:
		# Assumes PlayerStats has `gold` property.
		player_stats.gold = starting_gold

	if game_over_panel != null:
		game_over_panel.visible = false

	_update_round_label()
	round_changed.emit(current_round)


func is_run_active() -> bool:
	return run_active


func get_enemy_count_for_current_round() -> int:
	var raw_count := base_enemy_count + (current_round - 1)
	var max_spawns := _get_spawn_point_count()
	if max_spawns <= 0:
		return raw_count
	return min(raw_count, max_spawns)


func get_reward_for_round(round_number: int = current_round) -> int:
	# Exponential growth: reward_base * reward_growth^(round-1)
	return maxi(1, int(round(reward_base * pow(reward_growth, round_number - 1))))


func on_player_won_round() -> void:
	if not run_active:
		return

	var reward := get_reward_for_round(current_round)

	if player_stats != null:
		player_stats.gold += reward

	round_rewarded.emit(current_round, reward)

	current_round += 1
	_update_round_label()
	round_changed.emit(current_round)


func on_player_lost_round() -> void:
	if not run_active:
		return

	run_active = false

	if game_over_panel != null:
		game_over_panel.visible = true

	game_over.emit()


func _update_round_label() -> void:
	if round_label != null:
		round_label.text = "Round %d" % current_round


func _get_spawn_point_count() -> int:
	if enemy_spawn_points_root == null:
		return 0
	return enemy_spawn_points_root.get_child_count()
