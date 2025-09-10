@tool
extends EditorPlugin

var _toolbar: RustToolsToolbar
var _constants_generator: RustToolsConstantsFileGenerator
var _export_plugin: RustToolsExportPlugin


func _enter_tree() -> void:
	RustToolsSettings.register()

	_export_plugin = RustToolsExportPlugin.new()
	add_export_plugin(_export_plugin)
	_add_toolbar()
	_constants_generator = RustToolsConstantsFileGenerator.new()


func _exit_tree() -> void:
	_remove_toolbar()

	if _export_plugin:
		remove_export_plugin(_export_plugin)
		_export_plugin = null

	if _constants_generator:
		_constants_generator = null


func _build() -> bool:
	return _build_sync()


func _add_toolbar() -> void:
	_toolbar = preload("res://addons/rust_tools/toolbar.tscn").instantiate() as RustToolsToolbar
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, _toolbar)

	# Move the toolbar to the left of the run bar (best-effort), because that's where the build
	# button for C# is in the mono build as well.
	var parent := _toolbar.get_parent()
	for child in parent.get_children():
		if child.name.contains("EditorRunBar"):
			parent.move_child(_toolbar, child.get_index())
			break

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
	_toolbar.queue_free()
	_toolbar = null


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


func _post_build() -> void:
	if RustToolsSettings.get_enable_autoreload():
		RustToolsGdextension.reload_all()
