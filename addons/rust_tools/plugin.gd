@tool
extends EditorPlugin

var _toolbar: RustToolsToolbar

func _enter_tree() -> void:
	RustToolsSettings.register()
	
	_toolbar = preload("res://addons/rust_tools/toolbar.tscn").instantiate() as RustToolsToolbar
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, _toolbar)
	# Move the toolbar to the left of the run bar (best-effort), because that's where the build
	# button for C# is in the mono build as well.
	var parent := _toolbar.get_parent()
	for child in parent.get_children():
		if child.name.contains("EditorRunBar"):
			parent.move_child(_toolbar, child.get_index())
			break

func _exit_tree() -> void:
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, _toolbar)
	_toolbar.queue_free()
	_toolbar = null

func _build() -> bool:
	return RustToolsCargo.build_sync()
