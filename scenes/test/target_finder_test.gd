extends Node2D

func _ready() -> void:
	$BattleUnit.stats = $BattleUnit.stats
	$BattleUnit2.stats = $BattleUnit2.stats
	$BattleUnit3.stats = $BattleUnit3.stats
	$BattleUnit4.stats = $BattleUnit4.stats
		
	$BattleUnit3.target_finder.targets_in_range_changed.connect(
		func():
			print($BattleUnit3.target_finder.targets_in_range)
	)
	
	$BattleUnit4.target_finder.targets_in_range_changed.connect(
		func():
			print($BattleUnit4.target_finder.targets_in_range)
	)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("test1"):
		$BattleUnit3.target_finder.find_target()
		print($BattleUnit3.target_finder.target)
		$BattleUnit4.target_finder.find_target()
		print($BattleUnit4.target_finder.target)
		
		
	
