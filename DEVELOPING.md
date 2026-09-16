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

Documentation
-------------

Try to make UI self-documenting as much as possible. If that is not possible, document things in `README.md`.

If your change is user-facing, add it to the "Unreleased" section in `CHANGELOG.md` as well. This can be done in the same commit as the change itself.

Versioning
----------

Versioning of the plugin follows [Semantic Versioning](https://semver.org/). We consider something a "breaking change" if it requires user action after upgrading, for example if new required settings were added that must be configured.

Releasing
---------

Prepare the release:

- Update `CHANGELOG.md`.
- Update the version in `addons/rust_tools/plugin.cfg`.
- Tag the release commit using the format `vX.Y.Z`.

Release on the Godot Asset Library (deprecated):

- Push the tag to GitHub using `git push --tags`.
- Go to <https://godotengine.org/asset-library/asset/4365/edit>.
- Get the commit hash from `git log`.
- Update the Asset Version and the Download Commit/URL.

Release on the Godot Asset Store:

- Run `./asset_store/package_release.sh <VERSION>` where `<VERSION>` is the tag you just created. This places a `.zip` file in `/tmp` and prints its output path.
- Go to <https://store.godotengine.org/asset/thomastc/rust-tools/manage/#versions> and upload the new version.
