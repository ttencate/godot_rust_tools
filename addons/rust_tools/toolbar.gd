@tool
class_name RustToolsToolbar
extends Control

func _ready() -> void:
	# Reuse internal editor theme, discovered by reading the source code in
	# editor/gui/editor_run_bar.cpp.
	add_theme_stylebox_override("panel", get_theme_stylebox("LaunchPadNormal", "EditorStyles"))
	
	%RustBacktraceButton.button_pressed = RustToolsEnvironment.get_rust_backtrace()
	
	%BuildButton.pressed.connect(_build_button_pressed)
	%RustBacktraceButton.toggled.connect(_rust_backtrace_check_box_toggled)

func _build_button_pressed() -> void:
	RustToolsCargoBuild.run()

func _rust_backtrace_check_box_toggled(on: bool) -> void:
	RustToolsEnvironment.set_rust_backtrace(on)
