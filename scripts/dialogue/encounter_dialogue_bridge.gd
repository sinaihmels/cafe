class_name EncounterDialogueBridge
extends RefCounted

var session_service: SessionService
var dialogue_request: DialogueRequest

func remember_choice(key: StringName, value: Variant = true) -> void:
	var customer: CustomerInstance = get_customer()
	if customer == null or key == &"":
		return
	customer.dialogue_flags[key] = value

func apply_outcome(outcome_id: StringName) -> void:
	if session_service == null or outcome_id == &"":
		return
	session_service.apply_dialogue_outcome(outcome_id, dialogue_request.customer_runtime_id)

func get_customer() -> CustomerInstance:
	if session_service == null or dialogue_request == null:
		return null
	return session_service.get_customer_by_runtime_id(dialogue_request.customer_runtime_id)

func get_customer_index() -> int:
	if session_service == null or dialogue_request == null:
		return -1
	return session_service.find_customer_index_by_runtime_id(dialogue_request.customer_runtime_id)

func get_value(path: String) -> Variant:
	var customer: CustomerInstance = get_customer()
	match path:
		"card_id":
			return dialogue_request.card_id if dialogue_request != null else &""
		"leave_reason":
			return dialogue_request.leave_reason if dialogue_request != null else &""
		"customer_id":
			return customer.customer_def.customer_id if customer != null and customer.customer_def != null else &""
		"display_name":
			return customer.get_display_name() if customer != null else ""
		"order_id":
			return customer.get_order_id() if customer != null else &""
		"required_tags":
			return customer.get_preferences() if customer != null else PackedStringArray()
		"bonus_tags":
			return customer.get_bonus_tags() if customer != null else PackedStringArray()
		"minimum_quality":
			return customer.get_minimum_quality() if customer != null else 0
		"remaining_hunger":
			return customer.remaining_hunger if customer != null else 0
		"is_returning_visit":
			return customer.is_returning_visit() if customer != null else false
		"dialogue_flags":
			return customer.dialogue_flags if customer != null else {}
		"customer_type":
			return _customer_type_name(customer.get_customer_type()) if customer != null else ""
		_:
			if path.begins_with("dialogue_flags."):
				var flag_name: StringName = StringName(path.trim_prefix("dialogue_flags."))
				return customer.dialogue_flags.get(flag_name, false) if customer != null else false
	return null

func _customer_type_name(customer_type: int) -> String:
	match customer_type:
		GameEnums.CustomerType.PATIENT:
			return "patient"
		GameEnums.CustomerType.IMPATIENT:
			return "impatient"
		GameEnums.CustomerType.CRITIC:
			return "critic"
		GameEnums.CustomerType.CHAOTIC:
			return "chaotic"
		GameEnums.CustomerType.BOSS:
			return "boss"
		_:
			return "regular"
