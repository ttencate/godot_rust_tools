@tool
extends EditorPlugin

var _cargo_build: RustToolsCargoBuild
var _rust_backtrace: RustToolsRustBacktrace

func _enter_tree() -> void:
	RustToolsSettings.register()
	
	_cargo_build = RustToolsCargoBuild.new(self)
	_cargo_build.add_button()
	
	_rust_backtrace = RustToolsRustBacktrace.new(self)
	_rust_backtrace.add_checkbox()

func _exit_tree() -> void:
	_rust_backtrace.remove_checkbox()
	_rust_backtrace = null
	
	_cargo_build.remove_button()
	_cargo_build = null

func _build() -> bool:
	return _cargo_build.run()
