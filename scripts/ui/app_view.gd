class_name AppView
extends Control

signal continue_from_title_requested()
signal reset_profile_requested()
signal open_dough_select_requested()
signal open_decoration_requested()
signal close_decoration_requested()
signal start_run_requested(dough_id: StringName)
signal buy_upgrade_requested(upgrade_id: StringName)
signal buy_decoration_requested(decoration_id: StringName)
signal place_decoration_requested(slot_name: String, decoration_id: StringName)
signal toggle_equipment_requested(equipment_id: StringName, equipped: bool)
signal choose_reward_requested(reward_id: StringName)
signal buy_offer_requested(offer_id: StringName)
signal continue_after_shop_requested()
signal return_to_hub_requested()
signal start_boss_requested()
signal end_turn_requested()
signal play_card_requested(card_index: int)
signal focus_customer_requested(customer_index: int)
signal customer_item_requested(customer_index: int)
signal prep_item_requested(item_index: int)
signal oven_item_requested(slot_index: int)
signal table_item_requested(item_index: int)

@onready var _root: VBoxContainer = $Margin/Root
@onready var _title_label: Label = $Margin/Root/TitleLabel
@onready var _status_label: Label = $Margin/Root/StatusLabel
@onready var _meta_label: Label = $Margin/Root/MetaLabel
@onready var _hero_strip: HeroStripView = $Margin/Root/HeroStripView

@onready var _title_screen: TitleScreenView = $Margin/Root/ContentScroll/Content/TitleScreenView
@onready var _hub_screen: HubScreenView = $Margin/Root/ContentScroll/Content/HubScreenView
@onready var _decoration_screen: DecorationScreenView = $Margin/Root/ContentScroll/Content/DecorationScreenView
@onready var _dough_select_screen: DoughSelectScreenView = $Margin/Root/ContentScroll/Content/DoughSelectScreenView
@onready var _reward_screen: RewardScreenView = $Margin/Root/ContentScroll/Content/RewardScreenView
@onready var _shop_screen: ShopScreenView = $Margin/Root/ContentScroll/Content/ShopScreenView
@onready var _boss_intro_screen: BossIntroScreenView = $Margin/Root/ContentScroll/Content/BossIntroScreenView
@onready var _summary_screen: SummaryScreenView = $Margin/Root/ContentScroll/Content/SummaryScreenView
@onready var _encounter_screen: EncounterScreenView = $Margin/EncounterScreenView

func _ready() -> void:
	_connect_signals()
	_show_simple_screen(GameEnums.Screen.TITLE)
	_encounter_screen.visible = false

func render(session_service: SessionService, interaction_state: EncounterInteractionState) -> void:
	# Encounter owns a completely different authored layout, so the root shell acts as a simple screen router.
	if session_service.run_state.screen == GameEnums.Screen.ENCOUNTER:
		_root.visible = false
		_encounter_screen.visible = true
		_encounter_screen.render(session_service, interaction_state)
		return
	_root.visible = true
	_encounter_screen.visible = false
	_title_label.text = UiTextFormatter.screen_title(session_service.run_state.screen)
	_status_label.text = session_service.get_status_message()
	_meta_label.text = UiTextFormatter.build_meta_text(session_service)
	_hero_strip.render(session_service)
	_show_simple_screen(session_service.run_state.screen)
	match session_service.run_state.screen:
		GameEnums.Screen.TITLE:
			pass
		GameEnums.Screen.CAFE_HUB:
			_hub_screen.render(session_service)
		GameEnums.Screen.DECORATION:
			_decoration_screen.render(session_service)
		GameEnums.Screen.DOUGH_SELECT:
			_dough_select_screen.render(session_service)
		GameEnums.Screen.REWARD:
			_reward_screen.render(session_service)
		GameEnums.Screen.RUN_SHOP:
			_shop_screen.render(session_service)
		GameEnums.Screen.BOSS_INTRO:
			_boss_intro_screen.render(session_service)
		GameEnums.Screen.SUMMARY:
			_summary_screen.render(session_service)

func _show_simple_screen(screen: int) -> void:
	for section in _simple_screens():
		section.visible = false
	match screen:
		GameEnums.Screen.TITLE:
			_title_screen.visible = true
		GameEnums.Screen.CAFE_HUB:
			_hub_screen.visible = true
		GameEnums.Screen.DECORATION:
			_decoration_screen.visible = true
		GameEnums.Screen.DOUGH_SELECT:
			_dough_select_screen.visible = true
		GameEnums.Screen.REWARD:
			_reward_screen.visible = true
		GameEnums.Screen.RUN_SHOP:
			_shop_screen.visible = true
		GameEnums.Screen.BOSS_INTRO:
			_boss_intro_screen.visible = true
		GameEnums.Screen.SUMMARY:
			_summary_screen.visible = true

func _simple_screens() -> Array[Control]:
	var screens: Array[Control] = []
	screens.append(_title_screen)
	screens.append(_hub_screen)
	screens.append(_decoration_screen)
	screens.append(_dough_select_screen)
	screens.append(_reward_screen)
	screens.append(_shop_screen)
	screens.append(_boss_intro_screen)
	screens.append(_summary_screen)
	return screens

func _connect_signals() -> void:
	_title_screen.continue_requested.connect(func() -> void: continue_from_title_requested.emit())
	_title_screen.reset_profile_requested.connect(func() -> void: reset_profile_requested.emit())
	_hub_screen.open_dough_select_requested.connect(func() -> void: open_dough_select_requested.emit())
	_hub_screen.open_decoration_requested.connect(func() -> void: open_decoration_requested.emit())
	_hub_screen.reset_profile_requested.connect(func() -> void: reset_profile_requested.emit())
	_hub_screen.toggle_equipment_requested.connect(func(equipment_id: StringName, equipped: bool) -> void:
		toggle_equipment_requested.emit(equipment_id, equipped)
	)
	_hub_screen.buy_upgrade_requested.connect(func(upgrade_id: StringName) -> void:
		buy_upgrade_requested.emit(upgrade_id)
	)
	_hub_screen.buy_decoration_requested.connect(func(decoration_id: StringName) -> void:
		buy_decoration_requested.emit(decoration_id)
	)
	_decoration_screen.close_requested.connect(func() -> void: close_decoration_requested.emit())
	_decoration_screen.place_decoration_requested.connect(func(slot_name: String, decoration_id: StringName) -> void:
		place_decoration_requested.emit(slot_name, decoration_id)
	)
	_dough_select_screen.start_run_requested.connect(func(dough_id: StringName) -> void:
		start_run_requested.emit(dough_id)
	)
	_reward_screen.reward_requested.connect(func(reward_id: StringName) -> void:
		choose_reward_requested.emit(reward_id)
	)
	_shop_screen.offer_requested.connect(func(offer_id: StringName) -> void:
		buy_offer_requested.emit(offer_id)
	)
	_shop_screen.continue_requested.connect(func() -> void: continue_after_shop_requested.emit())
	_boss_intro_screen.start_boss_requested.connect(func() -> void: start_boss_requested.emit())
	_summary_screen.return_to_hub_requested.connect(func() -> void: return_to_hub_requested.emit())
	_encounter_screen.end_turn_requested.connect(func() -> void: end_turn_requested.emit())
	_encounter_screen.play_card_requested.connect(func(card_index: int) -> void: play_card_requested.emit(card_index))
	_encounter_screen.focus_customer_requested.connect(func(customer_index: int) -> void: focus_customer_requested.emit(customer_index))
	_encounter_screen.customer_item_requested.connect(func(customer_index: int) -> void: customer_item_requested.emit(customer_index))
	_encounter_screen.prep_item_requested.connect(func(item_index: int) -> void: prep_item_requested.emit(item_index))
	_encounter_screen.oven_item_requested.connect(func(slot_index: int) -> void: oven_item_requested.emit(slot_index))
	_encounter_screen.table_item_requested.connect(func(item_index: int) -> void: table_item_requested.emit(item_index))
