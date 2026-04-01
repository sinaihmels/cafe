extends SceneTree

func _init() -> void:
	var customer_def: DemoCustomerDef = DemoCustomerDef.new()
	customer_def.id = &"test_impatient"
	customer_def.display_name = "Test Impatient"
	customer_def.type = DemoEnums.CustomerType.IMPATIENT
	customer_def.patience = 3
	customer_def.stress_damage = 3
	var customer: DemoCustomerInstance = DemoCustomerInstance.new()
	customer.reset_from_def(customer_def)
	var encounter_state: DemoEncounterState = DemoEncounterState.new()
	encounter_state.active_customer = customer
	var player: DemoPlayerState = DemoPlayerState.new()
	player.stress = 10
	player.max_stress = 10
	var ai: CustomerAI = CustomerAI.new()
	var first_tick: Dictionary = ai.apply_end_turn(encounter_state, player)
	assert(not bool(first_tick.get("timed_out", true)), "First end turn should not timeout yet.")
	assert(customer.current_patience == 1, "Impatient customer should lose 2 patience.")
	var second_tick: Dictionary = ai.apply_end_turn(encounter_state, player)
	assert(bool(second_tick.get("timed_out", false)), "Second end turn should timeout.")
	assert(encounter_state.completed, "Encounter should be marked complete on timeout.")
	assert(player.stress < 10, "Timeout should reduce stress.")
	quit()
