class_name BattleHandler
extends Node

const ZOMBIE_TEST_POSITIONS := [
	Vector2i(8, 1),
	Vector2i(7, 4),
	Vector2i(8, 3),
	Vector2i(9, 5),
	Vector2i(9, 6)
]
const ZOMBIE := preload("res://data/enemies/zombie.tres")

signal player_won
signal enemy_won

@export var game_state: GameState
@export var game_area: PlayArea
@export var game_area_unit_grid: UnitGrid
@export var battle_unit_grid: UnitGrid
@export var trait_tracker: TraitTracker
@export var round_manager: RoundManager
@export var enemy_spawn_points_root: Node2D

@onready var scene_spawner: SceneSpawner = $SceneSpawner


func _ready() -> void:
	game_state.changed.connect(_on_game_state_changed)


func _setup_battle_unit(unit_coord: Vector2i, new_unit: BattleUnit) -> void:
	new_unit.stats.reset_health()
	new_unit.stats.reset_mana()
	new_unit.global_position = game_area.get_global_from_tile(unit_coord) + Vector2(0, -Arena.QUARTER_CELL_SIZE.y)
	new_unit.tree_exited.connect(_on_battle_unit_died)
	battle_unit_grid.add_unit(unit_coord, new_unit)


func _add_items(unit: Unit, new_unit: BattleUnit) -> void:
	unit.item_handler.copy_items_to(new_unit.item_handler)	
	new_unit.item_handler.items_changed.connect(_on_battle_unit_items_changed.bind(unit, new_unit))
	new_unit.item_handler.item_removed.connect(_on_battle_unit_item_removed.bind(new_unit))
	
	for item: Item in new_unit.item_handler.equipped_items:
		item.apply_modifiers(new_unit.modifier_handler)


func _add_trait_bonuses(new_unit: BattleUnit) -> void:
	for unit_trait: Trait in new_unit.stats.traits:
		if trait_tracker.active_traits.has(unit_trait):
			var trait_bonus := unit_trait.get_active_bonus(trait_tracker.unique_traits[unit_trait])
			trait_bonus.apply_bonus(new_unit)


func _clean_up_fight() -> void:
	get_tree().call_group("player_units", "queue_free")
	get_tree().call_group("enemy_units", "queue_free")
	get_tree().call_group("unit_abilities", "queue_free")
	get_tree().call_group("units", "show")


func _prepare_fight() -> void:
	for unit: Unit in game_area_unit_grid.get_all_units():
		unit.hide()
	
	for unit_coord: Vector2i in game_area_unit_grid.get_all_occupied_tiles():
		var unit: Unit = game_area_unit_grid.units[unit_coord]
		var new_unit := scene_spawner.spawn_scene(battle_unit_grid) as BattleUnit
		new_unit.add_to_group("player_units")
		new_unit.stats = unit.stats
		new_unit.stats.team = UnitStats.Team.PLAYER
		_setup_battle_unit(unit_coord, new_unit)
		_add_items(unit, new_unit)
		_add_trait_bonuses(new_unit)
	
	for unit_coord: Vector2i in _get_enemy_spawn_tiles():
		var new_unit := scene_spawner.spawn_scene(battle_unit_grid) as BattleUnit
		new_unit.add_to_group("enemy_units")
		new_unit.stats = ZOMBIE
		new_unit.stats.team = UnitStats.Team.ENEMY
		_setup_battle_unit(unit_coord, new_unit)
	
	
	UnitNavigation.update_occupied_tiles()
	var battle_units := get_tree().get_nodes_in_group("player_units") + get_tree().get_nodes_in_group("enemy_units")
	battle_units.shuffle()
	
	for battle_unit: BattleUnit in battle_units:
		battle_unit.unit_ai.enabled = true
		
		for item: Item in battle_unit.item_handler.equipped_items:
			item.apply_bonus_effect(battle_unit)


func _get_enemy_spawn_tiles() -> Array[Vector2i]:
	if enemy_spawn_points_root == null:
		return ZOMBIE_TEST_POSITIONS

	var enemy_count := ZOMBIE_TEST_POSITIONS.size()
	if round_manager != null:
		enemy_count = round_manager.get_enemy_count_for_current_round()

	var all_tiles := _get_spawn_tiles_from_markers()
	if all_tiles.is_empty():
		return ZOMBIE_TEST_POSITIONS

	all_tiles.shuffle()
	return all_tiles.slice(0, mini(enemy_count, all_tiles.size()))


func _get_spawn_tiles_from_markers() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []

	for child: Node in enemy_spawn_points_root.get_children():
		if child is Marker2D:
			var marker := child as Marker2D
			var tile := game_area.get_tile_from_global(marker.global_position)
			if battle_unit_grid.units.has(tile):
				tiles.append(tile)

	return tiles


func _on_battle_unit_died() -> void:
	# We already concluded the battle!
	# or we are quitting the game
	if not get_tree() or game_state.current_phase == GameState.Phase.PREPARATION:
		return
	
	if get_tree().get_node_count_in_group("enemy_units") == 0:
		game_state.current_phase = GameState.Phase.PREPARATION
		player_won.emit()
	if get_tree().get_node_count_in_group("player_units") == 0:
		game_state.current_phase = GameState.Phase.PREPARATION
		enemy_won.emit()


func _on_battle_unit_items_changed(unit: Unit, battle_unit: BattleUnit) -> void:
	battle_unit.item_handler.copy_items_to(unit.item_handler)
	
	for item: Item in battle_unit.item_handler.equipped_items:
		item.remove_modifiers(battle_unit.modifier_handler)
		item.apply_modifiers(battle_unit.modifier_handler)


func _on_battle_unit_item_removed(item: Item, battle_unit: BattleUnit) -> void:
	item.remove_modifiers(battle_unit.modifier_handler)


func _on_game_state_changed() -> void:
	match game_state.current_phase:
		GameState.Phase.PREPARATION:
			_clean_up_fight()
		GameState.Phase.BATTLE:
			_prepare_fight()
