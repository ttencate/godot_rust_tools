class_name RustToolsSettings
extends Node

# Editor settings
const _CARGO_EXECUTABLE := "rust_tools/cargo_executable"

# Project settings
const _CARGO_PACKAGE_DIRECTORIES := "rust_tools/cargo_package_directory"

## Registers all project and editor settings.
static func register() -> void:
	var editor_settings := EditorInterface.get_editor_settings()
	if not editor_settings.has_setting(_CARGO_EXECUTABLE):
		editor_settings.set_setting(_CARGO_EXECUTABLE, "cargo")
	editor_settings.add_property_info({
		"name": _CARGO_EXECUTABLE,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_GLOBAL_FILE,
	})
	
	if not ProjectSettings.has_setting(_CARGO_PACKAGE_DIRECTORIES):
		ProjectSettings.set_setting(_CARGO_PACKAGE_DIRECTORIES, PackedStringArray())
	# Unfortunately, there doesn't seem to be a way to add documentation to the property's tooltip.
	ProjectSettings.add_property_info({
		"name": _CARGO_PACKAGE_DIRECTORIES,
		"type": TYPE_PACKED_STRING_ARRAY,
		# We do not use PROPERTY_HINT_DIR, because it only allows directories inside the Godot
		# project. And we do not use PROPERTY_HINT_GLOBAL_DIR either, because it fills out an
		# absolute path whereas we want a relative path.
	})

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
