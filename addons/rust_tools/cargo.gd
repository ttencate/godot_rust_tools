@tool
class_name RustToolsCargo

## Invokes `cargo clean`. Returns `true` if successful.
static func clean() -> bool:
	var cargo_executable := RustToolsSettings.get_cargo_executable()
	if not _check_cargo_executable(cargo_executable):
		return false
	
	var cargo_package_dirs := RustToolsSettings.get_cargo_package_directories()
	for cargo_package_dir in cargo_package_dirs:
		if not _run_cargo(cargo_package_dir, cargo_executable, ['clean']):
			return false
	
	return true

## Invokes `cargo build`. Returns `true` if successful.
static func build() -> bool:
	var cargo_package_dirs := RustToolsSettings.get_cargo_package_directories()
	if cargo_package_dirs.is_empty():
		push_warning("No cargo package directories are configured, so no Rust code will be built. Go to Project > Project Settings... > Rust Tools and set Cargo Package Directories to a directory containing Cargo.toml, relative to the root of the Godot project.")
		# This is just a warning; technically no build was requested, so it succeeded.
		return true
	
	var cargo_executable := RustToolsSettings.get_cargo_executable()
	if not _check_cargo_executable(cargo_executable):
		return false
	
	for cargo_package_dir in cargo_package_dirs:
		if not _run_cargo(cargo_package_dir, cargo_executable, ['build']):
			return false
	
	return true

static func _check_cargo_executable(cargo_executable: String) -> bool:
	if cargo_executable.contains('/') or cargo_executable.contains('\\'):
		if FileAccess.file_exists(cargo_executable):
			return true
		else:
			push_error(
				"The configured cargo executable '%s' does not exist. Go to Editor > Editor Settings... > Rust Tools and set Cargo Executable to the absolute path to the cargo binary on your system." %
				[cargo_executable])
			return false
	else:
		# We are depending on cargo being in the PATH, but have no easy way to check for it.
		return true

## Runs the given cargo executable in the given working directory, passing the given arguments.
## The output is printed to the editor's Output pane.
## Returns true if successful.
##
## Important: the given args must currently not contain spaces or other characters that are special
## to any shell! If we need that in the future, we'll need to add shell-specific escaping code.
static func _run_cargo(cargo_package_dir: String, cargo_executable: String, args: PackedStringArray) -> bool:
	if not FileAccess.file_exists(cargo_package_dir + "/Cargo.toml"):
		push_error(
			"The configured cargo package directory '%s' does not contain a Cargo.toml file." %
			[cargo_package_dir])
		return false
	
	var subprocess := RustToolsSubprocess.new(cargo_executable)
	subprocess.set_args(args)
	subprocess.set_working_dir(cargo_package_dir)
	return subprocess.run_sync()
