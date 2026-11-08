# Open Road Driving Simulator — expanded prototype

This is an expanded Godot 4 prototype, not a finished game or exported APK.

## Implemented in this pass
- Procedural winding test route with an approximate 16.7 km route. At a constant 200 km/h, this is about five minutes.
- First-person driver camera and adjustable seat position, height and backrest.
- Touch HUD for throttle, brake, steering and clutch, plus keyboard controls.
- H-pattern touch gear selector for gears 1–6, neutral and reverse. Forward and reverse selection require clutch; reverse also requires near-zero speed.
- Basic RPM, engine stall and restart logic.
- Twenty selectable vehicle tuning profiles with different mass, power, torque metadata, redline, grip and target top speed metadata.
- Traffic presets: off, very low, low, medium, high and very high. Very high spawns 80 lightweight traffic cars.
- FPS cap selectable from 1 to 60; FPS and traffic settings are saved locally.
- Compatibility renderer as a lower-end-device starting point.

## Still incomplete
- The route now has a small procedural town, scattered rural houses, and simple gas-station, repair-shop and parking landmarks. These are primitive prototype scenery, not a detailed finished open world with a full street network or modeled interiors.
- Vehicle physics are simplified rigid-body forces, not realistic tire, suspension, differential or synchronized gearbox simulation. Vehicle profiles are starter tuning data, not complete unique car implementations.
- Traffic follows a route visually; there is no intelligent lane changing, collision avoidance or full traffic AI.
- Three low-resolution live camera mirrors are included with basic angle adjustment. Per-vehicle saved mirror presets and polished mirror housings are not finished.
- A basic dashboard, steering-wheel ring, pedals and gear lever are visible cockpit placeholders; they are not yet animated. Detailed vehicle meshes, engine audio, damage, save slots and profiling remain unfinished.
- Android export templates, signing, installation and testing on the Nokia 6.1 have not been completed. There is no APK in this repository.

## Run
Install Godot 4.x, clone/download this repository, open project.godot and run the main scene.

Keyboard: W throttle, S brake, A/D steering, Space clutch, N neutral, R reverse, 1–6 gears, E restart engine. The H-pattern touch controls are visible on screen.
