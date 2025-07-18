Developing Godot Rust Tools
===========================

So you want to help out making this plugin even better? Great! The Godot-Rust community thanks you! Here are some tips to get you started.

Project setup
-------------

This Git repository contains a Godot project at its root. This is the project used during plugin development. Apart from the Godot Rust Tools plugin itself, it also contains the [Godot Plugin Refresher](https://github.com/godot-extended-libraries/godot-plugin-refresher) plugin by willnationsdev, for quickly reloading the Rust Tools plugin.

Code style
----------

This plugin is 100% GDScript code, no Rust. This makes it easier to distribute in a cross-platform way.

- All GDScript code should be typed as much as possible (i.e. green line numbers in the editor).
- Class names must all begin with `RustTools` to avoid conflicts with other plugins or user code. This prefix is not part of the file name. For example, `cargo_build.gd` would contain `class_name RustToolsCargoBuild`.
- Scripts should compile without warnings. We have some non-default warnings enabled in the project.
- Follow the official [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
- Public functions should be documented with `##` style comments.