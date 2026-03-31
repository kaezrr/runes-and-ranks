# meta-name: Custom UnitAbility script
# meta-description: Instantiated when a BattleUnit casts its ability.
# meta-default: false
# meta-space-indent: 4
class_name _CLASS_
extends UnitAbility

func use() -> void:
	print("use this member var to access the casting BattleUnit: %s" % caster)
	SFXPlayer.play(sound)
	ability_cast_finished.emit()
