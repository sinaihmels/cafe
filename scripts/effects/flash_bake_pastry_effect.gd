class_name FlashBakePastryEffect
extends BaseEffect

@export_range(0.0, 1.0, 0.01) var burn_chance: float = 0.5

func apply(context: EffectContext) -> void:
	if context.session_service != null:
		context.session_service.flash_bake_pastry(burn_chance)
