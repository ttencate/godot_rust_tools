@tool
class_name RustToolsCargoBuild
extends RefCounted

const ESC := "\u001B"

var _foreground_colors := {
	30: "black",
	31: "red",
	32: "green",
	33: "yellow",
	34: "blue",
	35: "magenta",
	36: "cyan",
	37: "white",
}

var _editor_plugin: EditorPlugin
var _button: BaseButton

func _init(plugin: EditorPlugin) -> void:
	_editor_plugin = plugin

func add_button() -> void:
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_B
	key_event.ctrl_pressed = true
	key_event.shift_pressed = true
	var shortcut := Shortcut.new()
	shortcut.events.append(key_event)
	
	_button = Button.new()
	_button.icon = preload("res://addons/rust_tools/BuildRust.svg")
	_button.tooltip_text = 'Build Rust Project (cargo build)'
	_button.shortcut = shortcut
	_button.pressed.connect(_button_pressed)
	_editor_plugin.add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, _button)
	
	# Move the checkbox to the left of the Run Project button (best-effort).
	var parent := _button.get_parent()
	for container in parent.find_children("", "HBoxContainer", true, false):
		if container.get_parent() is PanelContainer:
			parent.remove_child(_button)
			container.add_child(_button)
			container.move_child(_button, 0)
			break

func remove_button() -> void:
	_button.queue_free()
	_button = null

func _button_pressed() -> void:
	# TODO This could be done asynchronously using OS.execute_with_pipe, which would take some
	# refactoring of run().
	run()

## Invokes `cargo build`. Returns `true` if successful.
func run() -> bool:
	var cargo_package_dirs := RustToolsSettings.get_cargo_package_directories()
	if cargo_package_dirs.is_empty():
		push_warning("No cargo package directories are configured, so no Rust code will be built. Go to Project > Project Settings... > Rust Tools and set Cargo Package Directories to a directory containing Cargo.toml, relative to the root of the Godot project.")
		# This is just a warning; technically no build was requested, so it succeeded.
		return true
	
	var cargo_executable := RustToolsSettings.get_cargo_executable()
	if cargo_executable.contains('/') or cargo_executable.contains('\\'):
		if not FileAccess.file_exists(cargo_executable):
			push_error(
				"The configured cargo executable '%s' does not exist. Go to Editor > Editor Settings... > Rust Tools and set Cargo Executable to the absolute path to the cargo binary on your system." %
				[cargo_executable])
			return false
	
	for cargo_package_dir in cargo_package_dirs:
		if not FileAccess.file_exists(cargo_package_dir + "/Cargo.toml"):
			push_error(
				"The configured cargo package directory '%s' does not contain a Cargo.toml file." %
				[cargo_package_dir])
			return false
		
		var output := []
		var exit_code: int
		# Spawn a shell to change directory first, because Godot's process API
		# does not support that.
		# Using cargo's `--manifest-path` makes it ignore `.cargo/config.toml`,
		# so that's not an option.
		# There is `cargo -C DIR build` but it's nightly only (as of 1.87.0),
		# so that's not an option either.
		match OS.get_name():
			"Web":
				# No process spawning, no Rust toolchain. Can't be done.
				push_error("Rust Tools is not supported on the web")
				return false
			"Windows":
				# I'm not sure about the cmd.exe incantation. It's probably similar. PRs welcome.
				push_error("Rust Tools is not supported on Windows yet")
				return false
			_:
				# All other platforms are Unix-like enough to have an sh-compatible shell.
				# From the manual: "Enclosing characters in single quotes preserves the literal
				# value of each character within the quotes. A single quote may not occur between
				# single quotes, even when preceded by a backslash."
				# This case is rare enough that we don't need to support it, but we can detect it.
				if "'" in cargo_package_dir:
					push_error("Cargo project path must not contain single quotes")
					return false
				var shell_command := (
					"cd '%s' && %s build --color=always" %
					[cargo_package_dir, cargo_executable]
				)
				exit_code = OS.execute(
					"/bin/sh", ["-c", shell_command], output, true, true)
		
		var color_output := _url_codes_to_bbcode(_color_codes_to_bbcode(output[0]))
		print_rich(color_output)

		if exit_code != 0:
			return false
	
	return true

## Converts terminal escape sequences to bbcode for display in Godot's console.
##
## [url]https://en.wikipedia.org/wiki/ANSI_escape_code#Colors[/url]
func _color_codes_to_bbcode(input: String) -> String:
	var regex := RegEx.create_from_string(ESC + r"\[([\d;]*)m")
	
	var output := ""
	var start := 0
	var re_match := regex.search(input, start)
	var close_tags := []
	while re_match:
		output += input.substr(start, re_match.get_start() - start)
		var parts := re_match.get_string(1).split(";")
		var params: Array[int] = []
		for i in len(parts):
			params.append(int(parts[i]))
		if len(params) == 0:
			params = [0]
		var i := 0
		while i < len(params):
			match params[i]:
				0:
					while not close_tags.is_empty():
						output += close_tags.pop_back()
				1:
					output += "[b]"
					close_tags.push_back("[/b]")
				var fg when fg in _foreground_colors:
					output += "[color=%s]" % [_foreground_colors[fg]]
					close_tags.push_back("[/color]")
				38:
					if i + 1 >= len(params):
						break
					match params[i + 1]:
						5:
							if i + 2 >= len(params):
								break
							var n := params[i + 2]
							output += "[color=#%s]" % [_color256(n).to_html(false)]
							close_tags.push_back("[/color]")
							i += 2
						2:
							if i + 4 >= len(params):
								break
							var r := params[i + 2]
							var g := params[i + 3]
							var b := params[i + 4]
							output += "[color=#%s]" % [Color.from_rgba8(r, g, b, 255).to_html(false)]
							close_tags.push_back("[/color]")
							i += 4
			i += 1
		
		start = re_match.get_end()
		re_match = regex.search(input, start)
	
	output += input.substr(start)
	while not close_tags.is_empty():
		output += close_tags.pop_back()
	
	return output

## Parses a 256-color escape sequence into a Godot [code]Color[/code].
##
## [url]https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit[/url]
func _color256(code: int) -> Color:
	var r: int
	var g: int
	var b: int
	if code < 16:
		var level: int
		if code > 8:
			level = 255
		elif code == 7:
			level = 229
		else:
			level = 205
		r = 127 if code == 8 else level if (code & 1) != 0 else 92 if code == 12 else 0
		g = 127 if code == 8 else level if (code & 2) != 0 else 92 if code == 12 else 0
		b = 127 if code == 8 else 238 if code == 4 else level if (code & 4) != 0 else 0
	elif code < 232:
		code -= 16
		var blue := code % 6
		code /= 6
		var green := code % 6
		code /= 6
		var red := code
		r = red   * 40 + 55 if red   != 0 else 0
		g = green * 40 + 55 if green != 0 else 0
		b = blue  * 40 + 55 if blue  != 0 else 0
	else:
		var gray := code - 232
		var level := gray * 10 + 8
		r = level
		g = level
		b = level
	return Color.from_rgba8(r, g, b)

## Converts ANSI terminal escape sequences for hyperlinks into bbcode [code][url][/code] tags.
func _url_codes_to_bbcode(input: String) -> String:
	var regex := RegEx.create_from_string(ESC + r"\]8;;(.*?)" + ESC + r"\\(.*?)" + ESC + r"]8;;" + ESC + r"\\")
	
	var output := ""
	var start := 0
	var re_match := regex.search(input, start)
	while re_match:
		output += input.substr(start, re_match.get_start() - start)
		
		output += "[url=%s]%s[/url]" % [re_match.get_string(1), re_match.get_string(2)]
		
		start = re_match.get_end()
		re_match = regex.search(input, start)
	
	output += input.substr(start)
	
	return output
