# Open Road Driving Simulator — Prototype

This repository now contains the **first Godot 4 prototype foundation**, not a finished commercial game or a complete APK.

## Current prototype
- Godot 4 project using the Compatibility renderer (OpenGL).
- Basic 3D test scene with a simple rigid-body car and a ground plane.
- Early vehicle controller with throttle, brake, steering, RPM, neutral, reverse and six forward gears.
- Gear selection is gated by the clutch; reverse also requires the car to be nearly stopped.
- Basic engine-stall logic when the clutch is released badly at low speed.
- A starter H-pattern mapping function intended for the future on-screen shifter.
- First-person cabin camera pivot with an early mouse-look test.

## Run
1. Install Godot 4.x.
2. Clone or download this repository.
3. Open project.godot in Godot.
4. Run the main scene.

### Prototype keyboard controls
- W: throttle
- S: brake
- A / D: steer
- Space: clutch (hold while selecting gears)
- N: neutral
- R: reverse (must be stopped and clutch held)
- 1–6: select a forward gear (clutch must be held)
- Hold right mouse button and move the mouse: look around

## Planned work (not implemented yet)
- Proper H-pattern shifter UI with visible gate movement and reverse lockout.
- Mobile touch controls and Android export configuration/testing.
- Proper wheel/suspension/tire physics, differential, engine torque curves, gearbox damage and audio.
- Driver seat adjustment, three live adjustable mirrors, saved per-car cockpit settings.
- Head-look controls for touch devices.
- Large streamed winding map with city, highway, mountain and rural areas.
- At least 20 distinct vehicles and optimized traffic presets up to a hardware-dependent target.
- Save system, settings menu, FPS cap (1–60), optimization and profiling on the target phone.

## Important
The controller is deliberately an early playable placeholder. It is not yet realistic vehicle physics. The requested five-minute cross-map route, complete cockpit, live mirrors, 20 cars, NPC traffic and Android-ready release still need substantial implementation and testing on real hardware.
