@tool
class_name RustToolsAnsiEscapeCodes

const ESC := "\u001B"

static var _foreground_colors := {
	30: "black",
	31: "red",
	32: "green",
	33: "yellow",
	34: "blue",
	35: "magenta",
	36: "cyan",
	37: "white",
}

## Converts terminal ANSI escape sequences to bbcode for display in Godot's console.
## Supports colors and clickable URL links.
static func to_bbcode(input: String) -> String:
	return _url_codes_to_bbcode(_color_codes_to_bbcode(input))

## Converts color escape sequences to bbcode.
##
## [url]https://en.wikipedia.org/wiki/ANSI_escape_code#Colors[/url]
static func _color_codes_to_bbcode(input: String) -> String:
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
static func _color256(code: int) -> Color:
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
##
## [url]https://en.wikipedia.org/wiki/ANSI_escape_code#Operating_System_Command_sequences[/url]
static func _url_codes_to_bbcode(input: String) -> String:
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
