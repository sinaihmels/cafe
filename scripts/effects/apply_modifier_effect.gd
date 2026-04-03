class_name ApplyModifierEffect
extends BaseEffect

@export var modifier_id: StringName = &""
@export var target_scope: int = GameEnums.ModifierTarget.PLAYER
@export var duration_override: int = -999

func apply(context: EffectContext) -> void:
	if context.session_service == null or modifier_id == &"":
		return
	match target_scope:
		GameEnums.ModifierTarget.PLAYER:
			context.session_service.add_player_buff(modifier_id, &"effect", effect_id, duration_override)
		GameEnums.ModifierTarget.CUSTOMER:
			context.session_service.add_status_to_target_customer(context.targets, modifier_id, &"effect", effect_id, duration_override)
		GameEnums.ModifierTarget.ITEM:
			context.session_service.add_status_to_target_item(context.targets, modifier_id, &"effect", effect_id, duration_override)
