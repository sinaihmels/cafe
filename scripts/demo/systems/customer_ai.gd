class_name CustomerAI
extends RefCounted

func apply_end_turn(encounter_state: DemoEncounterState, player_state: DemoPlayerState) -> Dictionary:
	if encounter_state == null or player_state == null or encounter_state.active_customer == null:
		return {"timed_out": false, "message": ""}
	var customer: DemoCustomerInstance = encounter_state.active_customer
	var patience_loss: int = _patience_loss_for_type(customer.get_type())
	customer.turns_waited += 1
	customer.current_patience -= patience_loss
	if customer.current_patience > 0:
		return {
			"timed_out": false,
			"message": "%s waits. Patience -%d." % [customer.get_display_name(), patience_loss],
		}
	var stress_loss: int = customer.customer_def.stress_damage + maxi(0, -customer.current_patience)
	match customer.get_type():
		DemoEnums.CustomerType.CRITIC:
			stress_loss += 1
		DemoEnums.CustomerType.BOSS:
			stress_loss += 2
		_:
			pass
	player_state.lose_stress(stress_loss)
	encounter_state.completed = true
	encounter_state.success = false
	encounter_state.turn_phase = DemoEnums.TurnPhase.IDLE
	return {
		"timed_out": true,
		"stress_loss": stress_loss,
		"message": "%s left disappointed. Stress -%d." % [customer.get_display_name(), stress_loss],
	}

func _patience_loss_for_type(customer_type: int) -> int:
	match customer_type:
		DemoEnums.CustomerType.PATIENT:
			return 1
		DemoEnums.CustomerType.IMPATIENT:
			return 2
		DemoEnums.CustomerType.CRITIC:
			return 1
		DemoEnums.CustomerType.CHAOTIC:
			return 2
		DemoEnums.CustomerType.BOSS:
			return 1
		_:
			return 1
