class_name GainEnergyEffect
extends BaseEffect

@export var amount: int = 1

func apply(context: EffectContext) -> void:
	context.player_state.energy += amount
	if context.event_bus != null:
		context.event_bus.emit_energy_changed(context.player_state.energy, amount)
