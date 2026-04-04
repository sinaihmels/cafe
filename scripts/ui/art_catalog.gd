class_name ArtCatalog
extends RefCounted

# Legacy path-based catalog kept for older references. The current editor-driven UI uses exported textures instead.
const ROOT_DIR: String = "res://assets/demo/"
const CARDS_DIR: String = ROOT_DIR + "cards/"
const CUSTOMERS_DIR: String = ROOT_DIR + "customers/"
const DOUGHS_DIR: String = ROOT_DIR + "doughs/"
const DISH_DIR: String = ROOT_DIR + "dish/"
const OVEN_DIR: String = ROOT_DIR + "oven/"
const UI_DIR: String = ROOT_DIR + "ui/"

const CARD_BASE_FILE: String = "base_card.png"
const CUSTOMER_PLACEHOLDER_FILE: String = "customer_placeholder.png"
const DOUGH_PLACEHOLDER_FILE: String = "dough_placeholder.png"
const DISH_PLACEHOLDER_FILE: String = "dish_placeholder.png"
const OVEN_PLACEHOLDER_FILE: String = "oven_placeholder.png"
const UI_BG_FILE: String = "demo_background.png"
const DISH_BASE_FILE: String = "dough_area_base.png"
const OVEN_BASE_FILE: String = "oven_base.png"

const CARD_ART_MAP: Dictionary = {
	&"reward_chocolate": "card_chocolate.png",
	&"reward_cinnamon": "card_cinnamon_sugar.png",
	&"reward_flash_bake": "card_flash_bake.png",
	&"starter_focus": "card_focus.png",
	&"starter_bake": "card_bake.png",
	&"starter_second_wind": "card_coffee.png",
	&"starter_cheese": "card_cream.png",
	&"starter_herbs": "card_cinnamon_sugar.png",
	&"starter_fold": "card_mix.png",
	&"starter_culture": "card_coffee.png",
	&"starter_proof": "card_bake.png",
}

const CUSTOMER_ART_MAP: Dictionary = {
	&"starter_regular": "customer_regular_guest.png",
	&"sweet_tooth_customer": "customer_patient_guest.png",
	&"fast_customer": "customer_impatient_guest.png",
	&"quality_customer": "customer_critic_guest.png",
	&"critic_boss": "customer_final_critic.png",
}

static func card_path(card_id: StringName) -> String:
	if CARD_ART_MAP.has(card_id):
		return CARDS_DIR + String(CARD_ART_MAP[card_id])
	return CARDS_DIR + CARD_BASE_FILE

static func card_base_path() -> String:
	return CARDS_DIR + CARD_BASE_FILE

static func customer_path(customer_id: StringName) -> String:
	if CUSTOMER_ART_MAP.has(customer_id):
		return CUSTOMERS_DIR + String(CUSTOMER_ART_MAP[customer_id])
	return CUSTOMERS_DIR + CUSTOMER_PLACEHOLDER_FILE

static func customer_placeholder_path() -> String:
	return CUSTOMERS_DIR + CUSTOMER_PLACEHOLDER_FILE

static func dough_path(dough_id: StringName) -> String:
	var id_text: String = String(dough_id)
	if id_text == "":
		return DOUGHS_DIR + DOUGH_PLACEHOLDER_FILE
	return DOUGHS_DIR + id_text + ".png"

static func dough_placeholder_path() -> String:
	return DOUGHS_DIR + DOUGH_PLACEHOLDER_FILE

static func dish_base_path() -> String:
	return DISH_DIR + DISH_BASE_FILE

static func dish_placeholder_path() -> String:
	return DISH_DIR + DISH_PLACEHOLDER_FILE

static func dish_overlay_path(overlay_key: StringName) -> String:
	var key_text: String = String(overlay_key)
	if key_text == "":
		return ""
	return DISH_DIR + key_text + "_overlay.png"

static func oven_base_path() -> String:
	return OVEN_DIR + OVEN_BASE_FILE

static func oven_placeholder_path() -> String:
	return OVEN_DIR + OVEN_PLACEHOLDER_FILE

static func oven_overlay_path(overlay_key: StringName) -> String:
	var key_text: String = String(overlay_key)
	if key_text == "":
		return ""
	return OVEN_DIR + key_text + "_overlay.png"

static func background_path() -> String:
	return UI_DIR + UI_BG_FILE
