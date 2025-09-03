## Static class (i.e. only static functions, should not be instantiated) acting as a centralized
## point to access the plugin's settings.
@tool
class_name RustToolsSettings
extends Object

# Editor settings
const _CARGO_EXECUTABLE := "rust_tools/cargo_executable"
const _CARGO_EXECUTABLE_INITIAL_VALUE := "cargo"
const _ENABLE_AUTORELOAD := "rust_tools/enable_autoreload"
const _ENABLE_AUTORELOAD_INITIAL_VALUE := true

# Project settings
<<<<<<< HEAD
const _CARGO_PACKAGE_DIRECTORIES := "rust_tools/cargo_package_directories"
const _GENERATED_CONSTANTS_FILE_PATHS := "rust_tools/config/generated_constants/generated_constants_file_paths"

## Registers all project and editor settings.
static func register() -> void:
	_register_editor_setting(_CARGO_EXECUTABLE, _CARGO_EXECUTABLE_INITIAL_VALUE, TYPE_STRING, PROPERTY_HINT_GLOBAL_FILE, "")
	_register_editor_setting(_ENABLE_AUTORELOAD, _ENABLE_AUTORELOAD_INITIAL_VALUE, TYPE_BOOL, PROPERTY_HINT_NONE, "")
	
	# We do not use PROPERTY_HINT_DIR, because it only allows directories inside the Godot project.
	# And we do not use PROPERTY_HINT_GLOBAL_DIR either, because it fills out an absolute path,
	# whereas we want a relative path.
	_register_project_setting(_CARGO_PACKAGE_DIRECTORIES, PackedStringArray(), TYPE_PACKED_STRING_ARRAY, PROPERTY_HINT_NONE, "", true)
	_register_project_setting(_GDEXTENSION_FILES, PackedStringArray(), TYPE_PACKED_STRING_ARRAY, PROPERTY_HINT_TYPE_STRING, "%d/%d:*.gdextension" % [TYPE_STRING, PROPERTY_HINT_FILE], true)
	_register_project_setting(_GENERATED_CONSTANTS_FILE_PATHS, PackedStringArray(), TYPE_PACKED_STRING_ARRAY, PROPERTY_HINT_NONE, "", true)

## Registers a single editor setting.
static func _register_editor_setting(name: String, initial_value: Variant, type: Variant.Type, hint: PropertyHint, hint_string: String) -> void:
	var editor_settings := EditorInterface.get_editor_settings()
	if not editor_settings.has_setting(name):
		editor_settings.set_setting(name, initial_value)
	editor_settings.set_initial_value(name, initial_value, false)
	editor_settings.add_property_info({
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string
	})

## Registers a single project setting.
static func _register_project_setting(name: String, initial_value: Variant, type: Variant.Type, hint: PropertyHint, hint_string: String, is_basic: bool) -> void:
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, initial_value)
	ProjectSettings.set_initial_value(name, initial_value)
	ProjectSettings.add_property_info({
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string,
	})
	ProjectSettings.set_as_basic(name, is_basic)

## Gets a single setting.
static func _get_setting(name: String, initial_value: Variant, is_editor: bool, type: Variant.Type) -> Variant:
	var result: Variant = EditorInterface.get_editor_settings().get_setting(name) if is_editor else ProjectSettings.get_setting(name)
	if not is_instance_of(result, type):
		return initial_value
	return result

## Returns the command to invoke cargo with. If it's on the PATH, this will just be "cargo",
## but it can also be an absolute path.
static func get_cargo_executable() -> String:
	return _get_setting(_CARGO_EXECUTABLE, _CARGO_EXECUTABLE_INITIAL_VALUE, true, TYPE_STRING)

## Returns the configured directories for the cargo package to be built.
static func get_cargo_package_directories() -> PackedStringArray:
	return _get_setting(_CARGO_PACKAGE_DIRECTORIES, PackedStringArray(), false, TYPE_PACKED_STRING_ARRAY)

## Returns the configured option to enable autoreloads or not.
static func get_enable_autoreload() -> bool:
	return _get_setting(_ENABLE_AUTORELOAD, _ENABLE_AUTORELOAD_INITIAL_VALUE, true, TYPE_BOOL)

## Returns the configured path to the .gdextension files this tool is managing.
static func get_gdextension_files() -> PackedStringArray:
	return _get_setting(_GDEXTENSION_FILES, PackedStringArray(), false, TYPE_PACKED_STRING_ARRAY)
