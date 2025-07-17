use godot::prelude::*;

struct ExampleExtension;

#[gdextension]
unsafe impl ExtensionLibrary for ExampleExtension {}
