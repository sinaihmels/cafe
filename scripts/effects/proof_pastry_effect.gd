class_name ProofPastryEffect
extends BaseEffect

func apply(context: EffectContext) -> void:
	if context.session_service != null:
		context.session_service.proof_active_pastry()
