class_name EncounterDirector
extends RefCounted

var _card_engine: CardEngine
var _food_composer: FoodComposer
var _demand_matcher: DemandMatcher
var _customer_ai: CustomerAI

func _init(
	card_engine: CardEngine,
	food_composer: FoodComposer,
	demand_matcher: DemandMatcher,
	customer_ai: CustomerAI
) -> void:
	_card_engine = card_engine
	_food_composer = food_composer
	_demand_matcher = demand_matcher
	_customer_ai = customer_ai

func start_encounter(
	encounter_def: DemoEncounterDef,
	customer_def: DemoCustomerDef,
	player_state: DemoPlayerState,
	encounter_state: DemoEncounterState,
	deck_defs: Array[DemoCardDef],
	passive_rules: PackedStringArray
) -> void:
	if encounter_def == null or customer_def == null or player_state == null or encounter_state == null:
		return
	encounter_state.turn_number = 1
	encounter_state.turn_phase = DemoEnums.TurnPhase.PLAYER
	encounter_state.pending_penalties = 0
	encounter_state.serve_history.clear()
	encounter_state.completed = false
	encounter_state.success = false
	encounter_state.last_result = {}
	encounter_state.status_message = ""
	encounter_state.active_customer = DemoCustomerInstance.new()
	encounter_state.active_customer.reset_from_def(customer_def)
	_food_composer.reset_for_encounter(encounter_state.food_state)
	player_state.deck_state.reset_from_defs(deck_defs)
	_card_engine.start_player_turn(player_state, encounter_state.food_state)
	encounter_state.status_message = "Encounter %d started: %s." % [
		encounter_def.index,
		customer_def.display_name,
	]
	if passive_rules.has("debug_echo"):
		encounter_state.status_message = "%s (debug)" % encounter_state.status_message

func play_card(
	hand_index: int,
	target_payload: Dictionary,
	player_state: DemoPlayerState,
	encounter_state: DemoEncounterState,
	passive_rules: PackedStringArray
) -> Dictionary:
	if encounter_state.completed:
		return {"success": false, "message": "Encounter already ended."}
	var result: Dictionary = _card_engine.play_card(
		player_state,
		encounter_state,
		passive_rules,
		hand_index,
		target_payload
	)
	encounter_state.status_message = String(result.get("message", ""))
	return result

func serve_dish(player_state: DemoPlayerState, encounter_state: DemoEncounterState) -> Dictionary:
	if encounter_state == null or encounter_state.active_customer == null:
		return {"success": false, "message": "No customer available."}
	if encounter_state.completed:
		return {"success": false, "message": "Encounter already ended."}
	var result: Dictionary = _demand_matcher.evaluate(
		encounter_state.food_state,
		encounter_state.active_customer.get_demands()
	)
	encounter_state.last_result = result
	encounter_state.serve_history.append(result)
	if bool(result.get("success", false)):
		encounter_state.completed = true
		encounter_state.success = true
		encounter_state.turn_phase = DemoEnums.TurnPhase.IDLE
		encounter_state.status_message = String(result.get("message", "Customer served."))
		return result
	var stress_loss: int = encounter_state.active_customer.customer_def.stress_damage
	if encounter_state.active_customer.get_type() == DemoEnums.CustomerType.BOSS:
		stress_loss += 2
	player_state.lose_stress(stress_loss)
	encounter_state.completed = true
	encounter_state.success = false
	encounter_state.turn_phase = DemoEnums.TurnPhase.IDLE
	result["stress_loss"] = stress_loss
	result["message"] = "%s Stress -%d." % [String(result.get("message", "Serve failed.")), stress_loss]
	encounter_state.status_message = String(result.get("message", "Serve failed."))
	return result

func resolve_end_turn(
	player_state: DemoPlayerState,
	encounter_state: DemoEncounterState,
	passive_rules: PackedStringArray
) -> Dictionary:
	if encounter_state == null or player_state == null:
		return {"success": false, "message": "Turn resolution failed."}
	if encounter_state.completed:
		return {"success": false, "message": "Encounter already ended."}
	_card_engine.end_player_turn_cleanup(player_state)
	encounter_state.turn_phase = DemoEnums.TurnPhase.ENEMY
	var ai_result: Dictionary = _customer_ai.apply_end_turn(encounter_state, player_state)
	if not encounter_state.completed and player_state.stress > 0:
		encounter_state.turn_number += 1
		encounter_state.turn_phase = DemoEnums.TurnPhase.PLAYER
		_card_engine.start_player_turn(player_state, encounter_state.food_state)
		encounter_state.status_message = String(ai_result.get("message", "New turn."))
	else:
		encounter_state.status_message = String(ai_result.get("message", "Encounter ended."))
	if passive_rules.has("debug_echo"):
		encounter_state.status_message = "%s (debug)" % encounter_state.status_message
	return ai_result
