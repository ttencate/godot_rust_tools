class_name RustToolsSettings
extends Node

# Editor settings
const _CARGO_EXECUTABLE := "rust_tools/cargo_executable"
const _ENABLE_AUTORELOAD := "rust_tools/enable_autoreload"
const _ENABLE_AUTORELOAD_DEFAULT := true

# Project settings
const _CARGO_PACKAGE_DIRECTORIES := "rust_tools/cargo_package_directories"
const _GDEXTENSION_FILES := "rust_tools/gdextension_files"
const _GDEXTENSION_FILES_DEFAULT := ["res://rust.gdextension"]

## Registers all project and editor settings.
static func register() -> void:
	var editor_settings := EditorInterface.get_editor_settings()
	if not editor_settings.has_setting(_CARGO_EXECUTABLE):
		editor_settings.set_setting(_CARGO_EXECUTABLE, "cargo")
	editor_settings.set_initial_value(_CARGO_EXECUTABLE, "cargo", false)
	editor_settings.add_property_info({
		"name": _CARGO_EXECUTABLE,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_GLOBAL_FILE,
	})
	if not editor_settings.has_setting(_ENABLE_AUTORELOAD):
		editor_settings.set_setting(_ENABLE_AUTORELOAD, _ENABLE_AUTORELOAD_DEFAULT)
	editor_settings.set_initial_value(_ENABLE_AUTORELOAD, _ENABLE_AUTORELOAD_DEFAULT, false)
	editor_settings.add_property_info({
		"name": _ENABLE_AUTORELOAD,
		"type": TYPE_BOOL,
	})
	
	if not ProjectSettings.has_setting(_CARGO_PACKAGE_DIRECTORIES):
		ProjectSettings.set_setting(_CARGO_PACKAGE_DIRECTORIES, PackedStringArray())
	ProjectSettings.set_initial_value(_CARGO_PACKAGE_DIRECTORIES, PackedStringArray())
	# Unfortunately, there doesn't seem to be a way to add documentation to the property's tooltip.
	ProjectSettings.add_property_info({
		"name": _CARGO_PACKAGE_DIRECTORIES,
		"type": TYPE_PACKED_STRING_ARRAY,
		# We do not use PROPERTY_HINT_DIR, because it only allows directories inside the Godot
		# project. And we do not use PROPERTY_HINT_GLOBAL_DIR either, because it fills out an
		# absolute path whereas we want a relative path.
	})
	ProjectSettings.set_as_basic(_CARGO_PACKAGE_DIRECTORIES, true)
	if not ProjectSettings.has_setting(_GDEXTENSION_FILES):
		ProjectSettings.set_setting(_GDEXTENSION_FILES, PackedStringArray(_GDEXTENSION_FILES_DEFAULT))
	ProjectSettings.set_initial_value(_GDEXTENSION_FILES, PackedStringArray(_GDEXTENSION_FILES_DEFAULT))
	# Unfortunately, there doesn't seem to be a way to add documentation to the property's tooltip.
	ProjectSettings.add_property_info({
		"name": _GDEXTENSION_FILES,
		"type": TYPE_PACKED_STRING_ARRAY,
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "%d/%d:*.gdextension" % [TYPE_STRING, PROPERTY_HINT_FILE],
	})
	ProjectSettings.set_as_basic(_GDEXTENSION_FILES, true)

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
		return PackedStringArray(_GDEXTENSION_FILES_DEFAULT)
	return result
