## Static class (i.e. only static functions, should not be instantiated) containing utility
## functions for working with *.gdextension files.
@tool
class_name RustToolsGdextension
extends Object

## Reloads all GDExtension files registered with the plugin.
## Returns [code]true[/code] on success.
static func reload_all() -> bool:
	var success := true
	for extension in RustToolsSettings.get_gdextension_files():
		# Even though the Project Settings window displays the files as res:// paths, they are
		# actually stored as uid:// paths. Apparently, reload_extension does not support those, so
		# we need to do the translation.
		if extension.begins_with("uid://"):
			extension = ResourceUID.uid_to_path(extension)
		var error := GDExtensionManager.reload_extension(extension)
		if error != OK:
			push_error("Failed to reload %s: %s" % [extension, error_string(error)])
			success = false
	return success
