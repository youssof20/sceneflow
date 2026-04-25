# SceneFlow

Smooth scene transitions for Godot 4.3+ (Lite).

## Why

`get_tree().change_scene_to_file()` cuts instantly and can cause a visible black flash. SceneFlow routes all scene changes through a single autoload (`SceneManager`) and swaps scenes at the *covered midpoint* of a transition.

## Install (Lite)

1. Copy `addons/sceneflow/` into your projects `addons/`.
2. Enable **SceneFlow** in `Project Settings � Plugins`.
3. Add the autoload:
   - Name: `SceneManager`
   - Path: `res://addons/sceneflow/scene_manager.gd`

## Pro (paid)

SceneFlow Pro adds presets (curves + per-transition params), async loading with progress, deep stacks, and more transitions.

- Itch.io: `https://chuumberry.itch.io/sceneflow`

## 30-second usage

```gdscript
SceneManager.go_to("res://scenes/next_scene.tscn")
```

## Transitions (Lite)

- NONE
- FADE (default)
- FADE_WHITE
- SLIDE_LEFT
- SLIDE_RIGHT

## No-code scene changes (Lite)

Add `res://addons/sceneflow/nodes/scene_link.tscn` to your scene, set `target_scene`, then call `trigger()` (for example from a button press).

## Runtime safety (Lite)

- Optional input blocking during transitions
- Configurable interrupt policy (ignore / queue / interrupt)

## Scene stack (Lite: single overlay)

```gdscript
SceneManager.push("res://scenes/pause_menu.tscn")
SceneManager.pop()
```

## API reference (Lite)

- **Signals**
  - `transition_started(from_path: String, to_path: String)`
  - `transition_completed(new_scene_path: String)`

- **Configurable properties**
  - `transition_color: Color`
  - `default_duration: float`
  - `default_transition: SceneManager.TransitionType`
  - `debug_logging: bool`
  - `block_input_during_transition: bool`
  - `interrupt_policy: SceneManager.InterruptPolicy` (`IGNORE`, `QUEUE`, `INTERRUPT`)

- **Methods**
  - `go_to(scene_path: String, transition: int = default_transition, duration: float = -1.0) -> void`
  - `reload(transition: int = default_transition, duration: float = -1.0) -> void`
  - `push(scene_path: String) -> void` (Lite supports one overlay)
  - `pop() -> void`
  - `stack_depth() -> int`

## Examples

```gdscript
SceneManager.default_transition = SceneManager.TransitionType.SLIDE_LEFT
SceneManager.default_duration = 0.35
SceneManager.go_to("res://scenes/level.tscn")
```

```gdscript
# Queue scene changes if spammed:
SceneManager.interrupt_policy = SceneManager.InterruptPolicy.QUEUE
SceneManager.go_to("res://scenes/a.tscn", SceneManager.TransitionType.FADE, 0.2)
SceneManager.go_to("res://scenes/b.tscn", SceneManager.TransitionType.FADE_WHITE, 0.2)
```