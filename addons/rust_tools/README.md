Godot Rust Tools
================

![Godot Rust Tools icon: a hammer inside the Rust gear, with small letters "rs" written next to it](icon.svg)

Godot Rust Tools, or "Rust Tools" for short, is a plugin for [Godot](https://godotengine.org/) 4 to help with development of [extensions](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/what_is_gdextension.html) written in [Rust](https://www.rust-lang.org/).

[gdext](https://godot-rust.github.io/) is the canonical and recommended library for using GDExtension from Rust, but this plugin does not depend on it and can work just as well with custom bindings.

Supported Platforms
------------

- Linux & Windows: Supported and tested, it should work right out the box.
- Android: Supported but untested, it should work right out the box for rooted devices.
- MacOS: Supported but untested, unclear if it works for the non-console version of the editor, report if works / doesn't work.

Installation
------------

Requires Godot 4.5 or greater.

Download this plugin's project files from GitHub. Copy the `addons/rust_tools` folder to the `addons` folder in your own Godot project, creating it if necessary. Files outside `addons/rust_tools` are not needed to use the plugin.

Usage
-----

After enabling the plugin, you'll see some new toolbar buttons to the left of the usual ones, marked with a little `rs` icon:

![A screenshot of Godot's top left toolbar, with three additional buttons: one displaying a call stack, one a broom and one a hammer. All three have an overlay with the letters "rs".](readme_images/toolbar.png)

From left to right:

- Rust Backtrace: toggle `RUST_BACKTRACE=1` in the environment of the running project, for more detailed panic reporting. Note that this only takes effect on newly started projects, not on currently running ones.
- Clean: runs `cargo clean`.
- Build: runs `cargo build`.

Build output goes to the Output pane at the bottom:

![A screenshot of Godot's Output pane, showing the output of a cargo build process](readme_images/build_output.png)

`cargo build` is also invoked automatically when you run or export your project, so you'll never get out-of-date code. However, due to limitations in the Godot API, these invocations must run synchronously, blocking the editor UI.

Before you can run the build, you will need to tell Rust Tools about your Rust code; see the REQUIRED items under [Configuration](#Configuration) below.

Configuration
-------------

### Project Settings

These can be found under Project > Project Settings… > Rust Tools.

- **Cargo Package Directories** (REQUIRED)

  You need to tell Rust Tools which cargo package(s) to build, by adding their path(s) to the Cargo Package Directories setting.

  Note that this path is relative to the Godot project itself, so:

  - If the Rust code is in a subfolder of the Godot project, specify the name of that folder here.
  - If the Rust code is in a sibling folder next to the Godot project, use ".." to indicate the parent folder, for example "../rust".

- **Gdextension Files** (REQUIRED)

  For autoreload to work, it needs to know which GDExtension files need to be reloaded. Specify those here.

- **Generated Constants File Paths**

  If specified Rust tools will automatically generate constants containing InputActions, Global Groups names and user-defined Layer Names. The file will be generated upon detecing a change in project settings; you can trigger it manually as well by using CommandPalette (ctrl+shift+p) Rust Tools -> Regenerate Constants.

### Editor Settings

These settings apply to all projects using Rust Tools, and can be found under Editor > Editor Settings… > Rust Tools.

- **Cargo Executable**

  If you don't have `cargo` in your `PATH`, you need to tell the editor where to find it. Set `Cargo Executable` to the absolute path to the `cargo` or `cargo.exe` executable.

  The default, plain `cargo`, is fine if its containing folder is on your `PATH`.

- **Enable Autoreload**

  By default, Rust Tools automatically reloads extensions after a rebuild. You can turn that off here. (Normally, Godot only reloads after the editor window loses and regains focus.)


License
-------

This plugin is under the MIT license, like Godot itself. See [LICENSE.md](LICENSE.md).

The Rust logo is distributed under the terms of the [Creative Commons Attribution license (CC-BY)](https://creativecommons.org/licenses/by/4.0/).

This project is not affiliated with, or endorsed by, the Rust Project or Rust Foundation.
