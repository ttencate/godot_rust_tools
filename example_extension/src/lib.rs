use godot::classes::{ISprite2D, Sprite2D};
use godot::prelude::*;

struct ExampleExtension;

#[gdextension]
unsafe impl ExtensionLibrary for ExampleExtension {}

/// A sprite that spins around its origin at a fixed speed.
#[derive(GodotClass)]
#[class(init, base = Sprite2D)]
struct Spinning {
    /// The speed at which the sprite spins, in radians per second.
    #[export]
    angular_speed: f32,

    base: Base<Sprite2D>,
}

#[godot_api]
impl ISprite2D for Spinning {
    fn physics_process(&mut self, delta: f32) {
        let angle_delta = self.angular_speed * delta;
        self.base_mut().rotate(angle_delta);
    }
}
