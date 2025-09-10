@tool
class_name RustToolsToolbar
extends Control

@onready var clean_button := %CleanButton
@onready var build_button := %BuildButton
@onready var backtrace_button := %RustBacktraceButton


func _ready() -> void:
	# Reuse internal editor theme, discovered by reading the source code in
	# editor/gui/editor_run_bar.cpp.
	add_theme_stylebox_override("panel", get_theme_stylebox("LaunchPadNormal", "EditorStyles"))
