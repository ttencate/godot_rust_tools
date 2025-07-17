Developing Godot Rust Tools
===========================

So you want to help out making this plugin even better? Great! Here are some tips to get you started.

Project setup
-------------

This Git repository contains a Godot project at its root. This is the project used during plugin development. Apart from the Godot Rust Tools plugin itself, it also contains the [Godot Plugin Refresher](https://github.com/godot-extended-libraries/godot-plugin-refresher) plugin by willnationsdev, for quickly reloading the Rust Tools plugin.

Code style
----------

This plugin is 100% GDScript code, no Rust. This makes it easier to distribute in a cross-platform way.

- All GDScript code should be typed as much as possible (i.e. green line numbers in the editor).
- Scripts should compile without warnings.