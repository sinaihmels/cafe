class_name CustomerFocusView
extends PanelContainer

signal focus_customer_requested(customer_index: int)
signal customer_target_requested(customer_index: int)

@export var stat_chip_scene: PackedScene
@export var selector_scene: PackedScene
@export var fallback_portrait: Texture2D

@onready var _empty_label: Label = $CustomerMargin/CustomerBody/CustomerEmptyLabel
@onready var _hero_row: HBoxContainer = $CustomerMargin/CustomerBody/CustomerHeroRow
@onready var _portrait: TextureRect = $CustomerMargin/CustomerBody/CustomerHeroRow/PortraitShell/PortraitMargin/PortraitBody/CustomerPortrait
@onready var _name_label: Label = $CustomerMargin/CustomerBody/CustomerHeroRow/CustomerInfo/CustomerNameLabel
@onready var _patience_slot: VBoxContainer = $CustomerMargin/CustomerBody/CustomerHeroRow/CustomerInfo/CustomerPatienceSlot
@onready var _request_label: Label = $CustomerMargin/CustomerBody/CustomerHeroRow/CustomerInfo/CustomerRequestLabel
@onready var _select_button: Button = $CustomerMargin/CustomerBody/SelectCustomerButton
@onready var _selectors: HFlowContainer = $CustomerMargin/CustomerBody/CustomerSelectors

var _focused_customer_index: int = -1

func _ready() -> void:
	_select_button.pressed.connect(_on_select_pressed)

func render(session_service: SessionService, interaction_state: EncounterInteractionState) -> void:
	UiSceneUtils.clear_children(_patience_slot)
	UiSceneUtils.clear_children(_selectors)
	if session_service.combat_state.active_customers.is_empty():
		_empty_label.visible = true
		_hero_row.visible = false
		_select_button.visible = false
		_selectors.visible = false
		_focused_customer_index = -1
		return
	_empty_label.visible = false
	_hero_row.visible = true
	_select_button.visible = true
	_selectors.visible = true
	_focused_customer_index = clampi(interaction_state.focused_customer_index, 0, session_service.combat_state.active_customers.size() - 1)
	var customer: CustomerInstance = session_service.combat_state.active_customers[_focused_customer_index]
	_portrait.texture = UiTextureLibrary.customer_texture(customer.customer_def) if customer.customer_def != null else fallback_portrait
	_name_label.text = customer.get_display_name()
	var patience_chip: StatChipView = _instantiate_stat_chip()
	patience_chip.configure("Patience", str(customer.current_patience), _patience_tone(customer.current_patience))
	_patience_slot.add_child(patience_chip)
	var hunger_chip: StatChipView = _instantiate_stat_chip()
	hunger_chip.configure("Hunger", str(customer.remaining_hunger), _hunger_tone(customer.remaining_hunger))
	_patience_slot.add_child(hunger_chip)
	var satisfaction_chip: StatChipView = _instantiate_stat_chip()
	satisfaction_chip.configure("Satisfaction", str(customer.satisfaction_score), _satisfaction_tone(customer.satisfaction_score))
	_patience_slot.add_child(satisfaction_chip)
	var satisfaction_tier: StringName = customer.get_satisfaction_tier()
	if satisfaction_tier != &"":
		var tier_chip: StatChipView = _instantiate_stat_chip()
		tier_chip.configure("Tier", _format_satisfaction_tier_label(satisfaction_tier), _satisfaction_tier_tone(satisfaction_tier))
		_patience_slot.add_child(tier_chip)
	for raw_talent_id in customer.get_talent_ids():
		var talent_chip: StatChipView = _instantiate_stat_chip()
		talent_chip.configure("Talent", _format_talent_label(StringName(raw_talent_id)), "accent")
		_patience_slot.add_child(talent_chip)
	if customer.is_returning_visit() or customer.has_return_scheduled:
		var returning_chip: StatChipView = _instantiate_stat_chip()
		returning_chip.configure("Returning", "Yes", "gold")
		_patience_slot.add_child(returning_chip)
	_request_label.text = UiTextFormatter.describe_customer_request(customer)
	var selected: bool = interaction_state.is_target_selected(&"customer", _focused_customer_index)
	var targetable: bool = interaction_state.is_zone_targetable(&"customer", _focused_customer_index)
	_select_button.text = "Customer Selected" if selected else "Select Customer"
	_select_button.disabled = not (selected or targetable)
	for customer_index in range(session_service.combat_state.active_customers.size()):
		var selector_customer: CustomerInstance = session_service.combat_state.active_customers[customer_index]
		var selector: CustomerSelectorView = _instantiate_selector()
		selector.configure(str(customer_index + 1), selector_customer.get_display_name(), customer_index == _focused_customer_index)
		var selector_index: int = customer_index
		selector.selected.connect(func() -> void:
			focus_customer_requested.emit(selector_index)
		)
		_selectors.add_child(selector)

func _patience_tone(current_patience: int) -> String:
	if current_patience <= 1:
		return "danger"
	if current_patience <= 2:
		return "gold"
	return "accent"

func _hunger_tone(remaining_hunger: int) -> String:
	if remaining_hunger >= 3:
		return "danger"
	if remaining_hunger == 2:
		return "gold"
	return "paper"

func _satisfaction_tone(satisfaction_score: int) -> String:
	if satisfaction_score >= CustomerInstance.EXTREMELY_SATISFIED_THRESHOLD:
		return "gold"
	if satisfaction_score >= CustomerInstance.SATISFIED_THRESHOLD:
		return "accent"
	return "paper"

func _satisfaction_tier_tone(satisfaction_tier: StringName) -> String:
	match satisfaction_tier:
		&"extremely_satisfied":
			return "gold"
		&"very_satisfied":
			return "accent"
		&"satisfied":
			return "paper"
		_:
			return "paper"

func _format_talent_label(talent_id: StringName) -> String:
	match talent_id:
		&"social":
			return "Social"
		_:
			return String(talent_id).capitalize()

func _format_satisfaction_tier_label(satisfaction_tier: StringName) -> String:
	match satisfaction_tier:
		&"extremely_satisfied":
			return "Extremely Satisfied"
		&"very_satisfied":
			return "Very Satisfied"
		&"satisfied":
			return "Satisfied"
		_:
			return "Warming Up"

func _on_select_pressed() -> void:
	if _focused_customer_index >= 0:
		customer_target_requested.emit(_focused_customer_index)

func _instantiate_stat_chip() -> StatChipView:
	var node: Node = UiSceneUtils.instantiate_required(stat_chip_scene, "CustomerFocusView.stat_chip_scene")
	var chip: StatChipView = node as StatChipView
	assert(chip != null, "CustomerFocusView.stat_chip_scene must instantiate StatChipView.")
	return chip

func _instantiate_selector() -> CustomerSelectorView:
	var node: Node = UiSceneUtils.instantiate_required(selector_scene, "CustomerFocusView.selector_scene")
	var selector: CustomerSelectorView = node as CustomerSelectorView
	assert(selector != null, "CustomerFocusView.selector_scene must instantiate CustomerSelectorView.")
	return selector
