@tool
class_name RustToolsExportPlugin
extends EditorExportPlugin

func _get_name() -> String:
	return "Rust Tools"

func _export_begin(_features: PackedStringArray, is_debug: bool, _path: String, _flags: int) -> void:
	var profile := "dev" if is_debug else "release"
	RustToolsCargo.build(profile).run_sync()
