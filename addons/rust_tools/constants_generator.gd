@tool
extends Object

class_name RustToolsConstantsFileGenerator

###############################################################################
# Properties                                                                 #
###############################################################################

# Signals

# Enums

# Constants

## All built-in actions provided by default by Godot.
const _BUILT_IN_ACTIONS: Array[StringName] = [
	&"ui_accept",
	&"ui_select",
	&"ui_cancel",
	&"ui_focus_next",
	&"ui_focus_prev",
	&"ui_left",
	&"ui_right",
	&"ui_up",
	&"ui_down",
	&"ui_page_up",
	&"ui_page_down",
	&"ui_home",
	&"ui_end",
	&"ui_cut",
	&"ui_copy",
	&"ui_paste",
	&"ui_undo",
	&"ui_redo",
	&"ui_text_completion_query",
	&"ui_text_completion_accept",
	&"ui_text_completion_replace",
	&"ui_text_newline",
	&"ui_text_newline_blank",
	&"ui_text_newline_above",
	&"ui_text_indent",
	&"ui_text_dedent",
	&"ui_text_backspace",
	&"ui_text_backspace_word",
	&"ui_text_backspace_word.macos",
	&"ui_text_backspace_all_to_left",
	&"ui_text_backspace_all_to_left.macos",
	&"ui_text_delete",
	&"ui_text_delete_word",
	&"ui_text_delete_word.macos",
	&"ui_text_delete_all_to_right",
	&"ui_text_delete_all_to_right.macos",
	&"ui_text_caret_left",
	&"ui_text_caret_word_left",
	&"ui_text_caret_word_left.macos",
	&"ui_text_caret_right",
	&"ui_text_caret_word_right",
	&"ui_text_caret_word_right.macos",
	&"ui_text_caret_up",
	&"ui_text_caret_down",
	&"ui_text_caret_line_start",
	&"ui_text_caret_line_start.macos",
	&"ui_text_caret_line_end",
	&"ui_text_caret_line_end.macos",
	&"ui_text_caret_page_up",
	&"ui_text_caret_page_down",
	&"ui_text_caret_document_start",
	&"ui_text_caret_document_start.macos",
	&"ui_text_caret_document_end",
	&"ui_text_caret_document_end.macos",
	&"ui_text_caret_add_below",
	&"ui_text_caret_add_below.macos",
	&"ui_text_caret_add_above",
	&"ui_text_caret_add_above.macos",
	&"ui_text_scroll_up",
	&"ui_text_scroll_up.macos",
	&"ui_text_scroll_down",
	&"ui_text_scroll_down.macos",
	&"ui_text_select_all",
	&"ui_text_select_word_under_caret",
	&"ui_text_select_word_under_caret.macos",
	&"ui_text_add_selection_for_next_occurrence",
	&"ui_text_skip_selection_for_next_occurrence",
	&"ui_text_clear_carets_and_selection",
	&"ui_text_toggle_insert_mode",
	&"ui_menu",
	&"ui_text_submit",
	&"ui_unicode_start",
	&"ui_graph_duplicate",
	&"ui_graph_delete",
	&"ui_filedialog_up_one_level",
	&"ui_filedialog_refresh",
	&"ui_filedialog_show_hidden",
	&"ui_swap_input_direction",
	&"spatial_editor/viewport_orbit_modifier_1",
	&"spatial_editor/viewport_orbit_modifier_2",
	&"spatial_editor/viewport_pan_modifier_1",
	&"spatial_editor/viewport_pan_modifier_2",
	&"spatial_editor/viewport_zoom_modifier_1",
	&"spatial_editor/viewport_zoom_modifier_2",
	&"spatial_editor/freelook_left",
	&"spatial_editor/freelook_right",
	&"spatial_editor/freelook_forward",
	&"spatial_editor/freelook_backwards",
	&"spatial_editor/freelook_up",
	&"spatial_editor/freelook_down",
	&"spatial_editor/freelook_speed_modifier",
	&"spatial_editor/freelook_slow_modifier"
]

# Export Variables

# Private Variables
var _current_actions: Array[String] = []
var _current_layers: Dictionary = {}
var _current_groups: Array[String] = []

## HACK - upon changing the settings signal is being emitted immienently, before user finishes typing.
## We append delay before regenerating constants file to make sure that settings has been properly and fully filled.
var _regenerate_constants_timer: Variant

# Onready Variables

###############################################################################
# Custom classes                                                              #
###############################################################################


## Stores info about user-named layers.
class NamedLayer:
	## Layer number.
	var layer: String
	## User-defined name.
	var name: String


###############################################################################
# Builtin functions                                                           #
###############################################################################


func _init() -> void:
	var user_constants := get_constants_from_project_settings()
	_current_actions = user_constants[0]
	_current_layers = user_constants[1]
	_current_groups = user_constants[2]
	ProjectSettings.settings_changed.connect(self._on_project_settings_changed)
	var command_palette: EditorCommandPalette = EditorInterface.get_command_palette()
	command_palette.add_command("Regenerate Constants", "rust_tools/regenerate_constants", _regenerate_constants_file.bind(true))


###############################################################################
# Public functions                                                            #
###############################################################################

## Returns user defined constants as an Array.
## Returned array contains following elements:
##
## - `Array[String]` of user-defined input actions.
## - `Dictionary` of user-defined layer names. Keys of Dictionary are Strings refering to given layer name (2d_physics/avoidance etc.) while values are `Array[NamedLayer]`.
## - `Array[String]` of user-defined GlobalGroups.
static func get_constants_from_project_settings() -> Array:
	var input_actions: Array[String] = []
	var layers: Dictionary = {}
	var groups: Array[String] = []

	# Believe or not, it is correct way to actually list all the properties.
	# We can't update the InputMap since it is being used by ProjectSettings.
	# Alternative would be parsing `.godot` file.
	# See: https://github.com/godotengine/godot/blob/6339f31a0217038ce6ed5e16776e34654895edc6/core/input/input_map.cpp#L299.
	for property in ProjectSettings.get_property_list():
		if property["name"].begins_with("input/"):
			_parse_input_action(property, input_actions)
		elif property["name"].begins_with("layer_names/"):
			_parse_layer(property, layers)
		elif property["name"].begins_with("global_group/"):
			_parse_global_group(property, groups)

	return [input_actions, layers, groups]


###############################################################################
# Private functions                                                           #
###############################################################################


static func _parse_layer(layer: Dictionary, layers: Dictionary) -> void:
	var user_name: String = ProjectSettings.get_setting(layer["name"])

	if not user_name:
		return

	var splitted_string: PackedStringArray = layer["name"].split("/")
	assert(splitted_string.size() == 3)

	# layer_names/>>category<</...
	var layer_category := splitted_string[1]
	# layer_names/category/>>layer_xx<<
	var layer_num := splitted_string[2].substr(splitted_string[2].find("_") + 1)

	var layer_info := NamedLayer.new()
	layer_info.name = user_name
	layer_info.layer = layer_num

	if not layers.has(layer_category):
		layers[layer_category] = [
			layer_info,
		]
	else:
		layers[layer_category].append(layer_info)


static func _parse_input_action(input_action: Dictionary, input_actions: Array[String]) -> void:
	var name: String = input_action["name"].substr(input_action["name"].find("/") + 1)

	if (
		not ProjectSettings.get_setting(RustToolsSettings._INCLUDE_BUILTIN_INPUT_ACTIONS)
		and _BUILT_IN_ACTIONS.find(name) != -1
	):
		return
	input_actions.append(name)


static func _parse_global_group(group: Dictionary, groups: Array[String]) -> void:
	var name: String = group["name"].substr(group["name"].find("/") + 1)
	groups.append(name)


func _regenerate_constants_file(force: bool = false) -> void:
	# HACK - clear delay.
	_regenerate_constants_timer = null

	# Unfortunately using UndoRedo and checking the action name is too unreliable – thus we must compare cached&new properties every single time.
	var user_constants := get_constants_from_project_settings()
	var new_actions: Array[String] = user_constants[0]
	var new_layers: Dictionary = user_constants[1]
	var new_groups: Array[String] = user_constants[2]

	if not force and not _has_constants_changed(_current_actions, new_actions) and not _has_constants_changed(_current_groups, new_groups) and not _has_layer_names_changed(new_layers):
		return

	_current_actions = new_actions
	_current_layers = new_layers
	_current_groups = new_groups

	var constants_definition: String = (
		_make_header()
		+ _make_constant_collection("InputActions", _current_actions, _make_str_constant_decl)
		+ _make_constant_collection("Groups", _current_groups, _make_str_constant_decl)
		+ make_layers_constants()
	)
	var paths: PackedStringArray = ProjectSettings.get_setting(
		RustToolsSettings._GENERATED_CONSTANTS_FILE_PATHS
	)

	for path in paths:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(constants_definition)


static func _make_header() -> String:
	return "// Auto generated by godot-rust-tools at " + Time.get_datetime_string_from_system() + "\n"

static func _make_str_constant_decl(name: String) -> String:
	return (
		"	pub const "
		+ name.replace(" ", "_").to_snake_case().to_upper()
		+ ": &'static str = \""
		+ name
		+ '"; \n'
	)


static func _make_named_layer_constant_decl(named_layer: NamedLayer) -> String:
	return (
		"	pub const "
		+ named_layer.name.replace(" ", "_").to_snake_case().to_upper()
		+ ": u32 = 1 << "
		+ str(named_layer.layer.to_int() - 1)
		+ "; \n"
	)


static func _make_layer_category_name(name: String) -> String:
	# Split layer name, for example 2d_physics => [2d, physics].
	# Identifiers in rust can't start with a number.
	var splitted_name := name.split("_")

	if splitted_name.size() == 2:
		name = splitted_name[1] + splitted_name[0]

	return name.to_pascal_case() + "Layers"


func _make_constant_collection(
	collection_name: String, items: Array, constant_formatter: Callable
) -> String:
	# Note – these newlines has been added & kept on purpose, for slightly better clarity.
	var struct_definition := (
		"""
#[allow(unused)]
pub struct {collection};

#[allow(unused)]
impl {collection} {
"""
		. format({"collection": collection_name})
	)

	for constant: Variant in items:
		struct_definition += constant_formatter.call(constant)

	struct_definition += "} \n"

	return struct_definition


func make_layers_constants() -> String:
	var layers_decl := ""

	for layer_category: String in _current_layers.keys():
		var layer_category_ident := _make_layer_category_name(layer_category)
		layers_decl += _make_constant_collection(layer_category_ident, _current_layers[layer_category], _make_named_layer_constant_decl)

	return layers_decl


func _has_constants_changed(old_constants: Array[String], new_constants: Array[String]) -> bool:
	if old_constants.size() != new_constants.size():
		return true

	# Theoretically has complexity of O(n^2).
	# In practice it should be faster than Dictionary (acting as a HashSet) for n < 10_000.
	return new_constants.any(func(action: String) -> bool: return not old_constants.has(action))


func _has_layer_names_changed(new_layers: Dictionary) -> bool:
	if (
		not _current_layers.has_all(new_layers.keys())
		or not new_layers.has_all(_current_layers.keys())
	):
		return true

	for key: String in _current_layers.keys():
		var old_named_layers: Array = _current_layers[key]
		var new_named_layers: Array = new_layers[key]

		if old_named_layers.size() != new_named_layers.size():
			return true

		for layer: NamedLayer in new_named_layers:
			for old_layer: NamedLayer in old_named_layers:
				if old_layer.name == layer.name:
					continue
			return false

	return false


###############################################################################
# Connections                                                                 #
###############################################################################


func _on_project_settings_changed() -> void:
	if _regenerate_constants_timer:
		_regenerate_constants_timer.timeout.disconnect(self._regenerate_constants_file)

	_regenerate_constants_timer = Engine.get_main_loop().create_timer(2.0)
	_regenerate_constants_timer.timeout.connect(self._regenerate_constants_file)
