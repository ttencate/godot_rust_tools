@tool
extends EditorPlugin


var _export_plugin: RustToolsExportPlugin
var _constants_generator: RustToolsConstantsFileGenerator
var _toolbar: RustToolsToolbar
var _project_settings: Control


func _enter_tree() -> void:
	RustToolsSettings.register()

	_export_plugin = RustToolsExportPlugin.new()
	add_export_plugin(_export_plugin)

	_constants_generator = RustToolsConstantsFileGenerator.new()

	_add_toolbar()
	_add_project_settings()


func _exit_tree() -> void:
	_remove_project_settings()
	_remove_toolbar()

	if _constants_generator:
		_constants_generator = null

	if _export_plugin:
		remove_export_plugin(_export_plugin)
		_export_plugin = null


func _build() -> bool:
	var build_before_run := RustToolsSettings.get_enable_build_before_run()
	if not build_before_run:
		print_rich("  Godot Rust Tools: [b][color=green]Skipping build before running[/color][/b]")
		return true
	return _build_sync()


func _add_toolbar() -> void:
	_toolbar = preload("res://addons/rust_tools/toolbar.tscn").instantiate() as RustToolsToolbar
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, _toolbar)

	# Move the toolbar to the left of the run bar (best-effort), because that's where the build
	# button for C# is in the mono build as well.
	var parent := _toolbar.get_parent()
	var editor_run_bar := _find_child_of_class(parent, "EditorRunBar")
	if editor_run_bar:
		parent.move_child(_toolbar, editor_run_bar.get_index())

	_toolbar.build_button.pressed.connect(_build_async)
	_toolbar.clean_button.pressed.connect(func() -> void: RustToolsCargo.clean().run_async())
	_toolbar.backtrace_button.button_pressed = RustToolsEnvironment.get_rust_backtrace()
	_toolbar.backtrace_button.toggled.connect(
		func(on: bool) -> void: RustToolsEnvironment.set_rust_backtrace(on)
	)


func _remove_toolbar() -> void:
	if not _toolbar:
		return

	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, _toolbar)
	_toolbar.free()
	_toolbar = null


## Adds a new tab "Rust Tools" to the Project Settings window.
func _add_project_settings() -> void:
	var project_settings_editor := _find_child_of_class(
		EditorInterface.get_base_control(), "ProjectSettingsEditor")
	if not project_settings_editor:
		return
	var tab_container := _find_child_of_class(project_settings_editor, "TabContainer")
	if not tab_container:
		return

	var scene := load("res://addons/rust_tools/RustToolsProjectSettings.tscn") as PackedScene
	_project_settings = scene.instantiate()
	tab_container.add_child(_project_settings)


## Removes any previously added "Rust Tools" tab from the Project Settings window.
func _remove_project_settings() -> void:
	if not _project_settings:
		return
	_project_settings.free()
	_project_settings = null


## Freezes the editor while building.
##
## While `await`ing without actually running any coroutine is fine and won't actually run anything asynchronusly,
## starting any coroutine while in `_build` won't postpone building the project (i.e. the project will be launched in the meanwhile).
## Rebuilding the library while project is already running causes instant UB.
func _build_sync() -> bool:
	_pre_build()
	# TODO - find a way to inform the user that project is being build.
	# This will only print to the console (can't output in the Editor itself because it is frozen).
	print_rich("  Godot Rust Tools: [b][color=green]Compiling project[/color][/b]")
	var build_status := RustToolsCargo.build("dev").run_sync()
	# Post build might fail, but we don't consider that a build failure because it shouldn't block
	# running the game.
	_post_build()
	return build_status


## Builds project in the background.
func _build_async() -> void:
	_pre_build()
	# Must be awaited to ensure corectness of `_post_build`.
	await RustToolsCargo.build("dev").run_async()
	_post_build()


## Pre-build hook. Contains all actions which should be triggered before the build.
func _pre_build() -> void:
	_constants_generator.regenerate_constants_file()


## Post-build hook. Contains all actions which should be triggered before the build.
func _post_build() -> void:
	if RustToolsSettings.get_enable_autoreload():
		RustToolsGdextension.reload_all()


## Returns the first child of the given node that has the given class name.
## If not found, logs an error and returns [code]null[/code].
static func _find_child_of_class(parent: Node, cls: String) -> Node:
	for child in parent.get_children():
		if child.get_class() == cls:
			return child
	push_error("Rust Tools: \"%s\" has no child of class \"%s\"" % [parent.get_path(), cls])
	return null
