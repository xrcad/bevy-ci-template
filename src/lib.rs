use bevy::prelude::*;

/// Entry point for both Android (via #[bevy_main]) and called by the desktop binary.
#[bevy_main]
pub fn main() {
    App::new().add_plugins(DefaultPlugins).run();
}
