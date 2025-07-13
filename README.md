Godot Rust Tools 
================

This is an addon for [Godot](https://godotengine.org/) 4 to help during development of Godot games that use Rust extensions through GDExtension:

- A "Build" button in the toolbar that invokes `cargo build`.
- Automatic `cargo build` when you run the project.
- A checkbox "Rust Backtrace" that sets `RUST_BACKTRACE=1` in the environment.

[godot-rust](https://godot-rust.github.io/) is the canonical library for Rust bindings, but this plugin is not dependent on it and can work just as well with custom bindings.

Building
--------

Cargo projects are detected automatically: Rust Tools scans the root directory of the project for any directories containing `Cargo.toml`.

All output from the compiler is shown afterwards in the Output pane, properly colourized.

Whenever you run the project or the current scene, `cargo build` is invoked automatically. Due to limitations of the Godot plugin API, the build is invoked on the main thread, and will freeze the UI until it's done.

Backtrace toggle
----------------

Due to limitations in the Rust standard library, the "Rust Backtrace" checkbox only takes effect on newly started processes. You cannot use it to enable backtraces on a currently running game.

License
-------

MIT, like Godot itself. See [LICENSE.md](LICENSE.md).
