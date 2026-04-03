extends SceneTree

func _init() -> void:
	var session: SessionService = SessionService.new()
	var meta: MetaProfileService = MetaProfileService.new()
	var event_bus: EventBus = EventBus.new()
	session.initialize(meta, event_bus)
	meta.reset_profile(session.content_library)
	assert(meta.profile_state.unlocked_dough_ids.has(&"sweet_dough"), "Sweet Dough should be unlocked by default.")
	assert(meta.profile_state.meta_currency >= 12, "Profile should start with test currency.")
	assert(session.purchase_decoration(&"chalkboard_menu"), "Should be able to buy a decoration with starting tokens.")
	assert(meta.profile_state.owned_decoration_ids.has(&"chalkboard_menu"), "Decoration ownership should persist in profile state.")
	assert(session.place_decoration("wall", &"chalkboard_menu"), "Owned decoration should be placeable in its slot.")
	assert(String(meta.profile_state.decoration_layout.get("wall", "")) == "chalkboard_menu", "Wall slot should store the placed decoration id.")
	assert(session.toggle_equipment(&"coffee_machine", true), "Should be able to buy and equip permanent equipment.")
	assert(meta.profile_state.owned_equipment_ids.has(&"coffee_machine"), "Equipment purchase should persist in profile state.")
	assert(meta.profile_state.equipped_equipment_ids.has(&"coffee_machine"), "Equipment should remain equipped in profile state.")
	quit()
