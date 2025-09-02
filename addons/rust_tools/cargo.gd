## Wrapper around the [code]cargo[/code] command line, representing a single invocation of cargo.

@tool
class_name RustToolsCargo
extends RefCounted

var _args: PackedStringArray
var _cargo_package_dirs: PackedStringArray
var _cargo_executable: String

## Static constructor.
## Returns an instance that calls [code]cargo build[/code] in all package directories, with the
## given [param profile].
static func build(profile: String) -> RustToolsCargo:
	return RustToolsCargo.new(['build', '--profile=%s' % profile])

## Static constructor.
## Returns an instance that calls [code]cargo clean[/code] in all package directories.
static func clean() -> RustToolsCargo:
	return RustToolsCargo.new(['clean'])

## Constructor implementation. Prefer to use one of the static constructors instead.
func _init(args: PackedStringArray) -> void:
	_args = args + PackedStringArray(["--color=always"])
	_cargo_executable = RustToolsSettings.get_cargo_executable()
	_cargo_package_dirs = RustToolsSettings.get_cargo_package_directories()

## Runs this command synchronously in all package directories.
## Returns [code]true[/code] if successful.
func run_sync() -> bool:
	if not _preflight_check_ok():
		return false
	for cargo_package_dir in _cargo_package_dirs:
		var subprocess := _new_subprocess(cargo_package_dir)
		if not subprocess.run_sync():
			return false
	RustToolsSettings.reload_gdextensions()
	return true

## Runs this command asynchronously (as a coroutine) in all package directories.
## Returns [code]true[/code] if successful.
func run_async() -> bool:
	if not _preflight_check_ok():
		return false
	for cargo_package_dir in _cargo_package_dirs:
		var subprocess := _new_subprocess(cargo_package_dir)
		if not subprocess.run_async():
			return false
		if not await subprocess.finished:
			return false
	RustToolsSettings.reload_gdextensions()
	return true

## Checks up front for any situations that are guaranteed to make the command fail, so we can report
## a more useful error message.
func _preflight_check_ok() -> bool:
	if _cargo_executable.contains('/') or _cargo_executable.contains('\\'):
		if not FileAccess.file_exists(_cargo_executable):
			push_error(
				"The configured cargo executable '%s' does not exist. Go to Editor > Editor Settings... > Rust Tools and set Cargo Executable to the absolute path to the cargo binary on your system." %
				[_cargo_executable])
			return false
	else:
		# We are depending on cargo being in the PATH, but have no easy way to check for it.
		pass

	if _cargo_package_dirs.is_empty():
		push_warning("No cargo package directories are configured, so no Rust code will be built. Go to Project > Project Settings... > Rust Tools and set Cargo Package Directories to a directory containing Cargo.toml, relative to the root of the Godot project.")

	for cargo_package_dir in _cargo_package_dirs:
		if not FileAccess.file_exists(cargo_package_dir + "/Cargo.toml"):
			push_error(
				"The configured cargo package directory '%s' does not contain a Cargo.toml file." %
				[cargo_package_dir])
			return false

	return true

## Creates an [i]unstarted[/i] subprocess to run this cargo command in the given directory.
func _new_subprocess(cargo_package_dir: String) -> RustToolsSubprocess:
	var subprocess := RustToolsSubprocess.new(_cargo_executable)
	subprocess.set_args(_args)
	subprocess.set_working_dir(cargo_package_dir)
	return subprocess
