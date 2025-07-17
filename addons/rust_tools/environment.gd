## Static utilities to handle environment variables.
class_name RustToolsEnvironment

## Returns whether [code]RUST_BACKTRACE[/code] is currently enabled in the environment.
static func get_rust_backtrace() -> bool:
	return OS.get_environment("RUST_BACKTRACE") not in ["", "0"]

## Sets the value of [code]RUST_BACKTRACE[/code] in the environment of the editor.
## This is inherited by the project process when it starts.
static func set_rust_backtrace(on: bool) -> void:
	if on:
		print("Setting RUST_BACKTRACE=1")
		OS.set_environment("RUST_BACKTRACE", "1")
	else:
		print("Unsetting RUST_BACKTRACE")
		OS.unset_environment("RUST_BACKTRACE")
