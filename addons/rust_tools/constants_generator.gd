@tool

class_name RustToolsConstantsFileGenerator
extends RefCounted

###############################################################################
# Properties                                                                 #
###############################################################################

# Signals

# Enums

# Constants

# Export Variables

# Private Variables
var _generated_file_hash: PackedByteArray

## HACK - upon changing the settings the signal is being emitted immediately, before the user finishes typing.
## We append a delay before regenerating the constants file to make sure that settings have been properly and fully filled.
var _regenerate_constants_timer: Variant

# Onready Variables

###############################################################################
# Custom classes                                                              #
###############################################################################


## Stores info about user-named layers.
class NamedLayer:
	## Layer ident (for example "11" for layer number 11).
	var layer: String
	## User-defined layer name.
	var name: String


class Constants:
	## Contains user-defined layer names.
	## Keys of Dictionary are Strings refering to given layer category (2d_physics/avoidance etc.) while values are `Array[NamedLayer]`.
	var layers: Dictionary = {}
	var input_actions: Array[String] = []
	var groups: Array[String] = []

	func _parse_layer(layer: Dictionary) -> void:
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
			layers[layer_category] = []
		layers[layer_category].append(layer_info)

	## Extracts setting's name from given ProjectSettings property.
	## Names are following format of `category/setting_name`.
	static func _parse_setting_name(property_setting: Dictionary) -> String:
		return property_setting["name"].split("/")[-1]

	func _parse_input_action(input_action: Dictionary) -> void:
		input_actions.append(_parse_setting_name(input_action))

	func _parse_global_group(group: Dictionary) -> void:
		groups.append(_parse_setting_name(group))


###############################################################################
# Builtin functions                                                           #
###############################################################################


func _init() -> void:
	var existing_hash := load_constants_file_hash()
	if existing_hash:
		_generated_file_hash = existing_hash

	regenerate_constants_file()

	ProjectSettings.settings_changed.connect(self._on_project_settings_changed)
	var command_palette: EditorCommandPalette = EditorInterface.get_command_palette()
	command_palette.add_command(
		"Regenerate Constants", "rust_tools/regenerate_constants", regenerate_constants_file
	)


###############################################################################
# Public functions                                                            #
###############################################################################


## Returns the hash of existing, already generated file (if present).
static func load_constants_file_hash() -> PackedByteArray:
	var paths: PackedStringArray = ProjectSettings.get_setting(
		RustToolsSettings.GENERATED_CONSTANTS_FILE_PATHS
	)

	if not paths:
		return []

	var file := FileAccess.open(paths[0], FileAccess.READ)
	if not file:
		return []

	return file.get_as_text().sha1_buffer()


## Returns user defined constants.
static func get_constants_from_project_settings() -> Constants:
	var constants := Constants.new()

	# Believe or not, this is the correct way to actually list all the properties.
	# We can't update the InputMap since it would overwrite all editor input actions.
	# The alternative would be parsing the `project.godot` file.
	# See: https://github.com/godotengine/godot/blob/6339f31a0217038ce6ed5e16776e34654895edc6/core/input/input_map.cpp#L299.
	for property in ProjectSettings.get_property_list():
		var property_name: String = property["name"]
		if property_name.begins_with("input/"):
			constants._parse_input_action(property)
		elif property_name.begins_with("layer_names/"):
			constants._parse_layer(property)
		elif property_name.begins_with("global_group/"):
			constants._parse_global_group(property)

	return constants


###############################################################################
# Private functions                                                           #
###############################################################################


## Regenerates&outputs constant files if user-defined constants (input actions, group names, layer names) has been changed.
func regenerate_constants_file() -> void:
	# HACK - clear delay.
	_regenerate_constants_timer = null

	var paths: PackedStringArray = ProjectSettings.get_setting(
		RustToolsSettings.GENERATED_CONSTANTS_FILE_PATHS
	)

	if not paths:
		return

	var constants_definition := _make_constants_definition_file()
	var new_hash := constants_definition.sha1_buffer()

	if _generated_file_hash and _generated_file_hash == new_hash:
		return

	_generated_file_hash = new_hash

	for path in paths:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(constants_definition)


func _make_constants_definition_file() -> String:
	# Unfortunately using UndoRedo and checking the action name is too unreliable – thus we must compare cached&new properties every single time.
	var new_constants := get_constants_from_project_settings()
	return (
		_make_header()
		+ _make_constant_collection(
			"input_actions", new_constants.input_actions, _make_str_constant_decl
		)
		+ _make_constant_collection("groups", new_constants.groups, _make_str_constant_decl)
		+ _make_layers_constants(new_constants.layers)
	)


static func _make_header() -> String:
	return (
		(
			"// Auto generated by godot-rust-tools at {datetime}\n"
			+ "#![rustfmt::skip]\n"
			+ "#![allow(unused)]\n"
		)
		. format({datetime = Time.get_datetime_string_from_system()})
	)


## Converts given name into `SCREAMING_CASE`.
static func _make_const_name(name: String) -> String:
	return name.replace(" ", "_").replace(".", "_").to_snake_case().to_upper()


static func _make_str_constant_decl(name: String) -> String:
	return '    pub const {formatted_name}: &\'static str = "{value}";\n'.format(
		{formatted_name = _make_const_name(name), value = name}
	)


static func _make_named_layer_constant_decl(named_layer: NamedLayer) -> String:
	return "    pub const {formatted_name}: u32 = {value};\n".format(
		{
			formatted_name = _make_const_name(named_layer.name),
			value = str(named_layer.layer.to_int() - 1)
		}
	)


static func _make_layer_category_name(name: String) -> String:
	# Split layer name, for example 2d_physics => [2d, physics].
	# Identifiers in rust can't start with a number.
	var splitted_name := name.split("_")

	if splitted_name.size() == 2:
		name = splitted_name[1] + splitted_name[0]

	return name.to_snake_case() + "_layers"


func _make_constant_collection(
	collection_name: String, items: Array, constant_formatter: Callable
) -> String:
	var struct_definition := "\npub mod {collection} {\n".format({collection = collection_name})

	for constant: Variant in items:
		struct_definition += constant_formatter.call(constant)

	struct_definition += "}\n"

	return struct_definition


func _make_layers_constants(layers: Dictionary) -> String:
	var layers_decl := ""

	for layer_category: String in layers.keys():
		var layer_category_ident := _make_layer_category_name(layer_category)
		layers_decl += _make_constant_collection(
			layer_category_ident, layers[layer_category], _make_named_layer_constant_decl
		)
	return layers_decl


###############################################################################
# Connections                                                                 #
###############################################################################


func _on_project_settings_changed() -> void:
	if _regenerate_constants_timer:
		_regenerate_constants_timer.timeout.disconnect(self.regenerate_constants_file)

	_regenerate_constants_timer = Engine.get_main_loop().create_timer(2.0)
	_regenerate_constants_timer.timeout.connect(self.regenerate_constants_file)
