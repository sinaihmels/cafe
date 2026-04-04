class_name ProofItemEffect
extends BaseEffect

func apply(context: EffectContext) -> void:
	if context.session_service == null:
		return
	context.session_service.proof_selected_prep_item(context.targets)
