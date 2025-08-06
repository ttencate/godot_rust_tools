class_name RustToolsSettings
extends Node

# Editor settings
const _CARGO_EXECUTABLE := "rust_tools/cargo_executable"
const _ENABLE_AUTORELOAD := "rust_tools/enable_autoreload"
const _ENABLE_AUTORELOAD_DEFAULT := true

# Project settings
const _CARGO_PACKAGE_DIRECTORIES := "rust_tools/cargo_package_directories"
const _GDEXTENSION_FILES := "rust_tools/gdextension_files"

## Registers all project and editor settings.
static func register() -> void:
	var editor_settings := EditorInterface.get_editor_settings()
	_register_editor_setting(_CARGO_EXECUTABLE, "cargo", TYPE_STRING, PROPERTY_HINT_GLOBAL_FILE, "", editor_settings)
	_register_editor_setting(_ENABLE_AUTORELOAD, _ENABLE_AUTORELOAD_DEFAULT, TYPE_BOOL, PROPERTY_HINT_NONE, "", editor_settings)
	
	# We do not use PROPERTY_HINT_DIR, because it only allows directories inside the Godot
	# project. And we do not use PROPERTY_HINT_GLOBAL_DIR either, because it fills out an
	# absolute path whereas we want a relative path.
	_register_project_setting(_CARGO_PACKAGE_DIRECTORIES, PackedStringArray(), TYPE_PACKED_STRING_ARRAY, PROPERTY_HINT_NONE, "", true)
	_register_project_setting(_GDEXTENSION_FILES, PackedStringArray(), TYPE_PACKED_STRING_ARRAY, PROPERTY_HINT_TYPE_STRING, "%d/%d:*.gdextension" % [TYPE_STRING, PROPERTY_HINT_FILE], true)

## Registers a single editor setting.
static func _register_editor_setting(name: String, value: Variant, type: Variant.Type, hint: PropertyHint, hint_string: String, editor_settings: EditorSettings) -> void:
	if editor_settings == null:
		editor_settings = EditorInterface.get_editor_settings()
	if not editor_settings.has_setting(name):
		editor_settings.set_setting(name, value)
	editor_settings.set_initial_value(name, value, false)
	editor_settings.add_property_info({
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string
	})

## Registers a single project setting.
static func _register_project_setting(name: String, value: Variant, type: Variant.Type, hint: PropertyHint, hint_string: String, is_basic: bool) -> void:
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, value)
	ProjectSettings.set_initial_value(name, value)
	ProjectSettings.add_property_info({
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string,
	})
	ProjectSettings.set_as_basic(name, is_basic)

## Returns the command to invoke cargo with. If it's on the PATH, this will just be "cargo",
## but it can also be an absolute path.
static func get_cargo_executable() -> String:
	var result: Variant = EditorInterface.get_editor_settings().get_setting(_CARGO_EXECUTABLE)
	if result is not String:
		return "cargo"
	return result

## Returns the configured directories for the cargo package to be built.
static func get_cargo_package_directories() -> PackedStringArray:
	var result: Variant = ProjectSettings.get_setting(_CARGO_PACKAGE_DIRECTORIES)
	if result is not PackedStringArray:
		return PackedStringArray()
	return result

## Returns the configured option to enable autoreloads or not.
static func get_enable_autoreload() -> bool:
	var result: Variant = ProjectSettings.get_setting(_ENABLE_AUTORELOAD)
	if result is not bool:
		return _ENABLE_AUTORELOAD_DEFAULT
	return result

## Returns the configured path to the .gdextension files this tool is managing.
static func get_gdextension_files() -> PackedStringArray:
	var result: Variant = ProjectSettings.get_setting(_GDEXTENSION_FILES)
	if result is not PackedStringArray:
		return PackedStringArray()
	return result
