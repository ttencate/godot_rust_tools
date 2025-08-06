@tool
class_name RustToolsToolbar
extends Control

func _ready() -> void:
	# Reuse internal editor theme, discovered by reading the source code in
	# editor/gui/editor_run_bar.cpp.
	add_theme_stylebox_override("panel", get_theme_stylebox("LaunchPadNormal", "EditorStyles"))
	
	%RustBacktraceButton.button_pressed = RustToolsEnvironment.get_rust_backtrace()
	
	%RustBacktraceButton.toggled.connect(_rust_backtrace_check_box_toggled)
	%CleanButton.pressed.connect(_clean_button_pressed)
	%BuildButton.pressed.connect(_build_button_pressed)

func _clean_button_pressed() -> void:
	# We need to await here even if we don't care about the outcome, because otherwise the
	# object gets deleted before the coroutine finishes running, which aborts the coroutine.
	await RustToolsCargo.clean().run_async()

func _build_button_pressed() -> void:
	# We need to await here even if we don't care about the outcome, because otherwise the
	# object gets deleted before the coroutine finishes running, which aborts the coroutine.
	await RustToolsCargo.build("dev").run_async()

func _rust_backtrace_check_box_toggled(on: bool) -> void:
	RustToolsEnvironment.set_rust_backtrace(on)
