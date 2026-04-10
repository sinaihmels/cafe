class_name UiPastryTagCatalog
extends RefCounted

const FALLBACK_FILL_COLOR: Color = Color(0.93, 0.88, 0.79, 0.96)
const FALLBACK_BORDER_COLOR: Color = Color(0.49, 0.36, 0.26, 0.96)
const FALLBACK_TEXT_COLOR: Color = Color(0.28, 0.20, 0.15, 1.0)

const TAG_PRESENTATIONS: Dictionary = {
	"sweet": {
		"label": "Sweet",
		"fill_color": Color(0.96, 0.76, 0.82, 0.98),
		"border_color": Color(0.77, 0.38, 0.53, 0.98),
		"text_color": Color(0.36, 0.14, 0.22, 1.0),
	},
	"chocolaty": {
		"label": "Chocolaty",
		"fill_color": Color(0.63, 0.43, 0.31, 0.98),
		"border_color": Color(0.35, 0.21, 0.12, 0.98),
		"text_color": Color(1.0, 0.96, 0.91, 1.0),
	},
	"savory": {
		"label": "Savory",
		"fill_color": Color(0.63, 0.78, 0.53, 0.98),
		"border_color": Color(0.30, 0.46, 0.24, 0.98),
		"text_color": Color(0.13, 0.24, 0.11, 1.0),
	},
	"salty": {
		"label": "Salty",
		"fill_color": Color(0.71, 0.82, 0.87, 0.98),
		"border_color": Color(0.38, 0.57, 0.65, 0.98),
		"text_color": Color(0.12, 0.23, 0.28, 1.0),
	},
	"flaky": {
		"label": "Flaky",
		"fill_color": Color(0.95, 0.84, 0.61, 0.98),
		"border_color": Color(0.74, 0.54, 0.22, 0.98),
		"text_color": Color(0.34, 0.24, 0.09, 1.0),
	},
	"shiny": {
		"label": "Shiny",
		"fill_color": Color(0.93, 0.84, 0.44, 0.98),
		"border_color": Color(0.73, 0.58, 0.14, 0.98),
		"text_color": Color(0.31, 0.24, 0.05, 1.0),
	},
	"creamy": {
		"label": "Creamy",
		"fill_color": Color(0.98, 0.92, 0.78, 0.98),
		"border_color": Color(0.79, 0.63, 0.40, 0.98),
		"text_color": Color(0.33, 0.24, 0.12, 1.0),
	},
	"luxurious": {
		"label": "Luxurious",
		"fill_color": Color(0.96, 0.80, 0.46, 0.98),
		"border_color": Color(0.77, 0.53, 0.16, 0.98),
		"text_color": Color(0.36, 0.22, 0.05, 1.0),
	},
	"pretty": {
		"label": "Pretty",
		"fill_color": Color(0.93, 0.76, 0.88, 0.98),
		"border_color": Color(0.72, 0.46, 0.69, 0.98),
		"text_color": Color(0.31, 0.14, 0.29, 1.0),
	},
	"sticky": {
		"label": "Sticky",
		"fill_color": Color(0.86, 0.66, 0.42, 0.98),
		"border_color": Color(0.66, 0.42, 0.14, 0.98),
		"text_color": Color(0.29, 0.17, 0.05, 1.0),
	},
	"fruity": {
		"label": "Fruity",
		"fill_color": Color(0.97, 0.65, 0.59, 0.98),
		"border_color": Color(0.78, 0.32, 0.31, 0.98),
		"text_color": Color(0.37, 0.10, 0.11, 1.0),
	},
	"tangy": {
		"label": "Tangy",
		"fill_color": Color(0.96, 0.91, 0.54, 0.98),
		"border_color": Color(0.77, 0.63, 0.14, 0.98),
		"text_color": Color(0.35, 0.27, 0.05, 1.0),
	},
	"airy": {
		"label": "Airy",
		"fill_color": Color(0.79, 0.90, 0.98, 0.98),
		"border_color": Color(0.42, 0.63, 0.80, 0.98),
		"text_color": Color(0.12, 0.24, 0.36, 1.0),
	},
}

const STATE_PRESENTATIONS: Dictionary = {
	"proofed": {
		"label": "Proofed",
		"fill_color": Color(0.75, 0.90, 0.77, 0.98),
		"border_color": Color(0.35, 0.58, 0.39, 0.98),
		"text_color": Color(0.12, 0.29, 0.15, 1.0),
	},
	"baked": {
		"label": "Baked",
		"fill_color": Color(0.87, 0.68, 0.41, 0.98),
		"border_color": Color(0.63, 0.38, 0.16, 0.98),
		"text_color": Color(0.27, 0.15, 0.05, 1.0),
	},
	"warm": {
		"label": "Warm",
		"fill_color": Color(0.96, 0.73, 0.50, 0.98),
		"border_color": Color(0.80, 0.39, 0.17, 0.98),
		"text_color": Color(0.39, 0.16, 0.05, 1.0),
	},
	"decorated": {
		"label": "Decorated",
		"fill_color": Color(0.88, 0.74, 0.96, 0.98),
		"border_color": Color(0.61, 0.40, 0.79, 0.98),
		"text_color": Color(0.22, 0.11, 0.35, 1.0),
	},
	"burned": {
		"label": "Burned",
		"fill_color": Color(0.63, 0.34, 0.29, 0.98),
		"border_color": Color(0.37, 0.17, 0.15, 0.98),
		"text_color": Color(1.0, 0.95, 0.93, 1.0),
	},
	"unproofed": {
		"label": "Unproofed",
		"fill_color": Color(0.79, 0.78, 0.72, 0.98),
		"border_color": Color(0.53, 0.50, 0.41, 0.98),
		"text_color": Color(0.22, 0.20, 0.15, 1.0),
	},
}

static func has_tag_presentation(tag_id: StringName) -> bool:
	return TAG_PRESENTATIONS.has(String(tag_id))

static func has_state_presentation(state_id: StringName) -> bool:
	return STATE_PRESENTATIONS.has(String(state_id))

static func presentation_for_tag(tag_id: StringName) -> Dictionary:
	var key: String = String(tag_id)
	if TAG_PRESENTATIONS.has(key):
		return TAG_PRESENTATIONS[key].duplicate(true)
	return _fallback_presentation(key)

static func presentation_for_state(state_id: StringName) -> Dictionary:
	var key: String = String(state_id)
	if STATE_PRESENTATIONS.has(key):
		return STATE_PRESENTATIONS[key].duplicate(true)
	return _fallback_presentation(key)

static func presentation_for_quality_delta(delta: int) -> Dictionary:
	if delta < 0:
		return {
			"label": "Quality",
			"fill_color": Color(0.74, 0.36, 0.31, 0.98),
			"border_color": Color(0.48, 0.20, 0.18, 0.98),
			"text_color": Color(1.0, 0.95, 0.93, 1.0),
		}
	return {
		"label": "Quality",
		"fill_color": Color(0.92, 0.78, 0.44, 0.98),
		"border_color": Color(0.74, 0.53, 0.18, 0.98),
		"text_color": Color(0.34, 0.22, 0.05, 1.0),
	}

static func label_for_tag(tag_id: StringName) -> String:
	return String(presentation_for_tag(tag_id).get("label", _humanize_token(String(tag_id), false)))

static func label_for_state(state_id: StringName) -> String:
	return String(presentation_for_state(state_id).get("label", _humanize_token(String(state_id), false)))

static func quality_label(delta: int) -> String:
	return "%sQ%d" % ["+" if delta >= 0 else "-", absi(delta)]

static func _fallback_presentation(token_text: String) -> Dictionary:
	return {
		"label": _humanize_token(token_text, false),
		"fill_color": FALLBACK_FILL_COLOR,
		"border_color": FALLBACK_BORDER_COLOR,
		"text_color": FALLBACK_TEXT_COLOR,
	}

static func _humanize_token(token_text: String, lowercase: bool) -> String:
	var words: PackedStringArray = token_text.replace("_", " ").split(" ", false)
	var output: PackedStringArray = PackedStringArray()
	for raw_word in words:
		var word: String = raw_word.strip_edges()
		if word == "":
			continue
		if lowercase:
			output.append(word.to_lower())
		else:
			output.append(word.substr(0, 1).to_upper() + word.substr(1).to_lower())
	return " ".join(output)
