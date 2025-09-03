@tool
extends EditorPlugin

var _toolbar: RustToolsToolbar
var _constants_generator: RustToolsConstantsFileGenerator
var _export_plugin: RustToolsExportPlugin

func _enter_tree() -> void:
	RustToolsSettings.register()

	_export_plugin = RustToolsExportPlugin.new()
	add_export_plugin(_export_plugin)

	_toolbar = preload("res://addons/rust_tools/toolbar.tscn").instantiate() as RustToolsToolbar
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, _toolbar)
	# Move the toolbar to the left of the run bar (best-effort), because that's where the build
	# button for C# is in the mono build as well.
	var parent := _toolbar.get_parent()
	for child in parent.get_children():
		if child.name.contains("EditorRunBar"):
			parent.move_child(_toolbar, child.get_index())
			break

	_constants_generator = RustToolsConstantsFileGenerator.new()

func _exit_tree() -> void:
	if _toolbar:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, _toolbar)
		_toolbar.queue_free()
		_toolbar = null

	if _export_plugin:
		remove_export_plugin(_export_plugin)
		_export_plugin = null

	if _constants_generator:
		_constants_generator.free()
		_constants_generator = null

func _build() -> bool:
	var build_success := RustToolsCargo.build("dev").run_sync()
	if not build_success:
		return false
	
	if RustToolsSettings.get_enable_autoreload():
		# This may also fail, but we don't consider that a build failure because it shouldn't block
		# running the game.
		RustToolsGdextension.reload_all()
	
	return true
