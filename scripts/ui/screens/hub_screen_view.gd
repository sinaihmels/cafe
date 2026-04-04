class_name HubScreenView
extends VBoxContainer

signal open_dough_select_requested()
signal open_decoration_requested()
signal reset_profile_requested()
signal toggle_equipment_requested(equipment_id: StringName, equipped: bool)
signal buy_upgrade_requested(upgrade_id: StringName)
signal buy_decoration_requested(decoration_id: StringName)

@export var choice_entry_scene: PackedScene

@onready var _start_run_button: Button = $StartRunButton
@onready var _decorate_button: Button = $DecorateButton
@onready var _reset_button: Button = $HubResetButton
@onready var _equipment_list: VBoxContainer = $EquipmentList
@onready var _upgrade_list: VBoxContainer = $UpgradeList
@onready var _decoration_list: VBoxContainer = $DecorationShopList
@onready var _layout_list: VBoxContainer = $CurrentLayoutList

const SLOT_NAMES: Array[String] = ["wall", "counter", "floor", "shelf", "exterior"]

func _ready() -> void:
	_start_run_button.pressed.connect(func() -> void: open_dough_select_requested.emit())
	_decorate_button.pressed.connect(func() -> void: open_decoration_requested.emit())
	_reset_button.pressed.connect(func() -> void: reset_profile_requested.emit())

func render(session_service: SessionService) -> void:
	UiSceneUtils.clear_children(_equipment_list)
	UiSceneUtils.clear_children(_upgrade_list)
	UiSceneUtils.clear_children(_decoration_list)
	UiSceneUtils.clear_children(_layout_list)
	var profile: MetaProfileState = session_service.get_profile_state()
	for equipment_value in session_service.get_available_equipment():
		var equipment: EquipmentDef = equipment_value
		var owned: bool = profile.owned_equipment_ids.has(equipment.equipment_id)
		var equipped: bool = profile.equipped_equipment_ids.has(equipment.equipment_id)
		var equipment_entry: ChoiceEntryView = _instantiate_choice_entry()
		equipment_entry.configure(
			UiTextureLibrary.equipment_texture(equipment),
			equipment.display_name,
			equipment.description,
			"Cost %d | %s" % [equipment.cost, "Equipped" if equipped else ("Owned" if owned else "Available")],
			"Unequip" if equipped else ("Unlock And Equip" if not owned else "Equip")
		)
		var equipment_id: StringName = equipment.equipment_id
		var next_equipped: bool = not equipped
		equipment_entry.primary_action_requested.connect(func() -> void:
			toggle_equipment_requested.emit(equipment_id, next_equipped)
		)
		_equipment_list.add_child(equipment_entry)
	for upgrade_value in session_service.get_available_shop_upgrades():
		var upgrade: ShopUpgradeDef = upgrade_value
		var owned_upgrade: bool = profile.purchased_shop_upgrade_ids.has(upgrade.upgrade_id)
		var upgrade_entry: ChoiceEntryView = _instantiate_choice_entry()
		upgrade_entry.configure(
			UiTextureLibrary.shop_upgrade_texture(upgrade),
			upgrade.display_name,
			upgrade.description,
			"Cost %d | %s" % [upgrade.cost, "Owned" if owned_upgrade else "Available"],
			"" if owned_upgrade else "Buy Upgrade"
		)
		if not owned_upgrade:
			var upgrade_id: StringName = upgrade.upgrade_id
			upgrade_entry.primary_action_requested.connect(func() -> void:
				buy_upgrade_requested.emit(upgrade_id)
			)
		_upgrade_list.add_child(upgrade_entry)
	for decoration_value in session_service.get_available_decorations():
		var decoration: DecorationDef = decoration_value
		var owned_decoration: bool = profile.owned_decoration_ids.has(decoration.decoration_id)
		var decoration_entry: ChoiceEntryView = _instantiate_choice_entry()
		decoration_entry.configure(
			UiTextureLibrary.decoration_texture(decoration),
			decoration.display_name,
			decoration.description,
			"Cost %d | %s" % [decoration.cost, "Owned" if owned_decoration else "Available"],
			"" if owned_decoration else "Buy Decoration"
		)
		if not owned_decoration:
			var decoration_id: StringName = decoration.decoration_id
			decoration_entry.primary_action_requested.connect(func() -> void:
				buy_decoration_requested.emit(decoration_id)
			)
		_decoration_list.add_child(decoration_entry)
	for slot_name in SLOT_NAMES:
		var current_value: String = String(profile.decoration_layout.get(slot_name, ""))
		var current_def: DecorationDef = session_service.content_library.get_decoration(StringName(current_value))
		var layout_entry: ChoiceEntryView = _instantiate_choice_entry()
		layout_entry.configure(
			UiTextureLibrary.decoration_texture(current_def),
			slot_name.capitalize(),
			"Current cafe slot",
			current_value if current_value != "" else "Empty"
		)
		_layout_list.add_child(layout_entry)

func _instantiate_choice_entry() -> ChoiceEntryView:
	var node: Node = UiSceneUtils.instantiate_required(choice_entry_scene, "HubScreenView.choice_entry_scene")
	var entry: ChoiceEntryView = node as ChoiceEntryView
	assert(entry != null, "HubScreenView.choice_entry_scene must instantiate ChoiceEntryView.")
	return entry
