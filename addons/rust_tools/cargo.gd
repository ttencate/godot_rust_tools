@tool
class_name RustToolsCargo

## Invokes [code]cargo build[/code]. Returns [code]true[/true] if successful.
static func build_sync() -> bool:
	var cargo_package_dirs := RustToolsSettings.get_cargo_package_directories()
	if not _check_cargo_package_dirs(cargo_package_dirs):
		# Nothing to build; this is considered a success.
		return true
	
	var cargo_executable := RustToolsSettings.get_cargo_executable()
	if not _check_cargo_executable(cargo_executable):
		return false
	
	for cargo_package_dir in cargo_package_dirs:
		if not _cargo_subprocess(cargo_package_dir, cargo_executable, ['build']).run_sync():
			return false
	
	return true

## Invokes [code]cargo build[/code] asynchronously.
static func build_async() -> void:
	var cargo_package_dirs := RustToolsSettings.get_cargo_package_directories()
	if not _check_cargo_package_dirs(cargo_package_dirs):
		return
	
	var cargo_executable := RustToolsSettings.get_cargo_executable()
	if not _check_cargo_executable(cargo_executable):
		return
	
	for cargo_package_dir in cargo_package_dirs:
		var subprocess := _cargo_subprocess(cargo_package_dir, cargo_executable, ['build'])
		if not subprocess.run_async():
			return
		var success: bool = await subprocess.finished
		if not success:
			return

## Invokes [code]cargo clean[/code] synchronously.
static func clean_async() -> void:
	var cargo_executable := RustToolsSettings.get_cargo_executable()
	if not _check_cargo_executable(cargo_executable):
		return
	
	var cargo_package_dirs := RustToolsSettings.get_cargo_package_directories()
	for cargo_package_dir in cargo_package_dirs:
		var subprocess := _cargo_subprocess(cargo_package_dir, cargo_executable, ['clean'])
		if not subprocess.run_async():
			return
		var success: bool = await subprocess.finished
		if not success:
			return

static func _check_cargo_package_dirs(cargo_package_dirs: PackedStringArray) -> bool:
	if cargo_package_dirs.is_empty():
		push_warning("No cargo package directories are configured, so no Rust code will be built. Go to Project > Project Settings... > Rust Tools and set Cargo Package Directories to a directory containing Cargo.toml, relative to the root of the Godot project.")
		return false
	else:
		return true

static func _check_cargo_package_dir(cargo_package_dir: String) -> bool:
	if not FileAccess.file_exists(cargo_package_dir + "/Cargo.toml"):
		push_error(
			"The configured cargo package directory '%s' does not contain a Cargo.toml file." %
			[cargo_package_dir])
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

## Creates an [i]unstarted[/i] subprocess that will run the given cargo executable in the given
## working directory, passing the given arguments.
## The output is printed to the editor's Output pane.
## Returns true if successful.
static func _cargo_subprocess(cargo_package_dir: String, cargo_executable: String, args: PackedStringArray) -> RustToolsSubprocess:
	if not _check_cargo_package_dir(cargo_package_dir):
		return null
	
	args.append("--color=always")
	
	var subprocess := RustToolsSubprocess.new(cargo_executable)
	subprocess.set_args(args)
	subprocess.set_working_dir(cargo_package_dir)
	return subprocess
