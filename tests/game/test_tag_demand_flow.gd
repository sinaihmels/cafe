extends SceneTree

func _init() -> void:
	var session: SessionService = SessionService.new()
	var meta: MetaProfileService = MetaProfileService.new()
	var event_bus: EventBus = EventBus.new()
	session.initialize(meta, event_bus)
	meta.reset_profile(session.content_library)

	var sweet_customer: CustomerInstance = CustomerInstance.new()
	sweet_customer.reset_from_def(session.content_library.get_customer(&"sweet_tooth_customer"))
	var chocolate_pastry: ItemInstance = session.create_item_instance(&"chocolate_pastry")
	assert(chocolate_pastry != null, "Chocolate pastry item should load.")
	var sweet_outcome: Dictionary = session._score_item_for_customer(chocolate_pastry, sweet_customer)
	assert(int(sweet_outcome.get("reputation_delta", 0)) == 2, "Sweet Tooth should score chocolate as a matching bonus tag.")
	assert(int(sweet_outcome.get("tips", 0)) == 3, "Sweet Tooth should pay base reward plus one chocolate-tag bonus.")

	var quality_customer: CustomerInstance = CustomerInstance.new()
	quality_customer.reset_from_def(session.content_library.get_customer(&"quality_customer"))
	var plain_pastry: ItemInstance = session.create_item_instance(&"sweet_pastry")
	assert(plain_pastry != null, "Sweet pastry item should load.")
	var quality_fail: Dictionary = session._score_item_for_customer(plain_pastry, quality_customer)
	assert(int(quality_fail.get("reputation_delta", 0)) < 0, "Quality Seeker should reject pastries missing the required decorated tag.")

	var quality_pastry: ItemInstance = session.create_item_instance(&"perfect_sweet_pastry")
	assert(quality_pastry != null, "Perfect Sweet Pastry item should load.")
	quality_pastry.quality = 1
	var quality_success: Dictionary = session._score_item_for_customer(quality_pastry, quality_customer)
	assert(int(quality_success.get("reputation_delta", 0)) == 4, "Quality Seeker should reward decorated pastries that meet the quality threshold and bonus tags.")
	assert(int(quality_success.get("tips", 0)) == 5, "Quality Seeker should pay base reward plus both quality-related bonus tags.")
	quit()
