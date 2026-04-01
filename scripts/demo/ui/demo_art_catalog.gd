class_name DemoArtCatalog
extends RefCounted

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

static func card_path(card_id: StringName) -> String:
	var id_text: String = String(card_id)
	if id_text == "":
		return CARDS_DIR + CARD_BASE_FILE
	return CARDS_DIR + id_text + ".png"

static func card_base_path() -> String:
	return CARDS_DIR + CARD_BASE_FILE

static func customer_path(customer_id: StringName) -> String:
	var id_text: String = String(customer_id)
	if id_text == "":
		return CUSTOMERS_DIR + CUSTOMER_PLACEHOLDER_FILE
	return CUSTOMERS_DIR + id_text + ".png"

static func customer_placeholder_path() -> String:
	return CUSTOMERS_DIR + CUSTOMER_PLACEHOLDER_FILE

static func dough_path(dough_id: StringName) -> String:
	var id_text: String = String(dough_id)
	if id_text == "":
		return DOUGHS_DIR + DOUGH_PLACEHOLDER_FILE
	return DOUGHS_DIR + id_text + ".png"

static func dough_placeholder_path() -> String:
	return DOUGHS_DIR + DOUGH_PLACEHOLDER_FILE

static func dish_stage_path(stage_key: StringName) -> String:
	var key_text: String = String(stage_key)
	if key_text == "":
		return DISH_DIR + DISH_PLACEHOLDER_FILE
	return DISH_DIR + key_text + ".png"

static func dish_placeholder_path() -> String:
	return DISH_DIR + DISH_PLACEHOLDER_FILE

static func oven_stage_path(stage_key: StringName) -> String:
	var key_text: String = String(stage_key)
	if key_text == "":
		return OVEN_DIR + OVEN_PLACEHOLDER_FILE
	return OVEN_DIR + key_text + ".png"

static func oven_placeholder_path() -> String:
	return OVEN_DIR + OVEN_PLACEHOLDER_FILE

static func background_path() -> String:
	return UI_DIR + UI_BG_FILE
