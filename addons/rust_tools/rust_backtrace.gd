## Installs a checkbox "Rust Backtrace" in the toolbar, which sets RUST_BACKTRACE=1
## in the environment. This only takes effect for newly started runs.
@tool
class_name RustToolsRustBacktrace
extends RefCounted

var _editor_plugin: EditorPlugin
var _checkbox: CheckBox

func _init(plugin: EditorPlugin) -> void:
	_editor_plugin = plugin

func add_checkbox() -> void:
	_checkbox = CheckBox.new()
	_checkbox.text = "Rust Backtrace"
	_checkbox.button_pressed = OS.get_environment("RUST_BACKTRACE") not in ["", "0"]
	_checkbox.toggled.connect(_checkbox_toggled)
	_editor_plugin.add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, _checkbox)
	
	# Move the checkbox to the left of the run bar (best-effort).
	var parent := _checkbox.get_parent()
	for child in parent.get_children():
		if child.name.contains("EditorRunBar"):
			parent.move_child(_checkbox, child.get_index())
			break

func remove_checkbox() -> void:
	_checkbox.queue_free()
	_checkbox = null

func _checkbox_toggled(on: bool) -> void:
	if on:
		print_debug("Setting RUST_BACKTRACE=1")
		OS.set_environment("RUST_BACKTRACE", "1")
	else:
		print_debug("Unsetting RUST_BACKTRACE")
		OS.unset_environment("RUST_BACKTRACE")
