# Shake System Reimagined

```text
░██████╗██╗░░██╗░█████╗░██╗░░██╗███████╗  ░██████╗██╗░░░██╗░██████╗████████╗███████╗███╗░░░███╗
██╔════╝██║░░██║██╔══██╗██║░██╔╝██╔════╝  ██╔════╝╚██╗░██╔╝██╔════╝╚══██╔══╝██╔════╝████╗░████║
╚█████╗░███████║███████║█████═╝░█████╗░░  ╚█████╗░░╚████╔╝░╚█████╗░░░░██║░░░█████╗░░██╔████╔██║
░╚═══██╗██╔══██║██╔══██║██╔═██╗░██╔══╝░░  ░╚═══██╗░░╚██╔╝░░░╚═══██╗░░░██║░░░██╔══╝░░██║╚██╔╝██║
██████╔╝██║░░██║██║░░██║██║░╚██╗███████╗  ██████╔╝░░░██║░░░██████╔╝░░░██║░░░███████╗██║░╚═╝░██║
╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝  ╚═════╝░░░░╚═╝░░░╚═════╝░░░░╚═╝░░░╚══════╝╚═╝░░░░░╚═╝

██████╗░███████╗██╗███╗░░░███╗░█████╗░░██████╗░██╗███╗░░██╗███████╗██████╗░
██╔══██╗██╔════╝██║████╗░████║██╔══██╗██╔════╝░██║████╗░██║██╔════╝██╔══██╗
██████╔╝█████╗░░██║██╔████╔██║███████║██║░░██╗░██║██╔██╗██║█████╗░░██║░░██║
██╔══██╗██╔══╝░░██║██║╚██╔╝██║██╔══██║██║░░╚██╗██║██║╚████║██╔══╝░░██║░░██║
██║░░██║███████╗██║██║░╚═╝░██║██║░░██║╚██████╔╝██║██║░╚███║███████╗██████╔╝
╚═╝░░╚═╝╚══════╝╚═╝╚═╝░░░░░╚═╝╚═╝░░╚═╝░╚═════╝░╚═╝╚═╝░░╚══╝╚══════╝╚═════╝░
```

I rescripted my most popular Shake module because it was a disaster.. memory leaks everywhere, unoptimized uncentralized code and buggy behavior.

> **EXTREMELY IMPORTANT:** REMEMBER TO USE `:Remove()` WHEN YOU'RE DONE WITH A SHAKE SYSTEM TO AVOID UNWANTED MEMORY LEAKS.  
> **THIS IS NOW REQUIRED BOTH ON SERVER AND CLIENT!!!**

If you find any memory leaks tell me and I will fix them!!

## Implementation

This module wraps RbxCameraShaker with server/client replication, player targeting, proximity falloff, tweened settings, rotation bias, muting, and cleanup management.

RbxCameraShaker generates the underlying noise. This wrapper applies positional noise directly and uses its frame-to-frame difference for compatible rotation.

## Introduction

This module creates camera shake effects, driven from the server or from a client.

Every shake mixes two independent effects:

- **Positional shake**: slides the camera around its position (rumble / vibration feel)
- **Rotational shake**: tilts the camera's aim: pitch, yaw and roll (impact / disorientation feel)

## Setup

Store the module somewhere the client can see it. `ReplicatedStorage` is recommended.

Install the complete RbxCameraShaker `CameraShaker` ModuleScript as a child of this module, or directly inside `ReplicatedStorage`.

Keep its `CameraShakeInstance` and `CameraShakePresets` child modules inside `CameraShaker`.

The bundled client script sets up the client side automatically. It is configured to run even from `ReplicatedStorage`, so no manual setup is needed.

You only need to call `ShakeModule.CLIENT_LOAD()` yourself if you remove that bundled script.

## Usage

### 1. Require the module

```lua
local ShakeModule = require(game.ReplicatedStorage.CamShakeSystem)
```

### 2. Create a new Shake system instance

```lua
local ShakeSystem = ShakeModule.new()
```

By default the shake replicates to every player, including players who join later.

To make it affect only certain players, pass a table of `Player` instances. **SERVER ONLY.**

Example:

```lua
local ShakeSystem = ShakeModule.new({game.Players.z3ck200})
```

Be careful to `:Remove()` player-limited systems when you're done using them, because once all of those players leave, the system is just useless garbage piling up.

You can add more players to the list later by calling `ShakeSystem:AddPlayers()` with a table of players. This only works on systems created with a player list.

Example:

```lua
ShakeSystem:AddPlayers({game.Players.z3ck200})
```

### 3. Set the Shake Settings

```lua
ShakeSystem:SetValue(PositionMagnitude, RotationMagnitude, Roughness, TweenSpeed)
```

- **PositionMagnitude**: strength of the positional shake. Slides the camera along its own axes: X (left/right), Y (up/down) and Z (forward/back). Reads best near geometry, nearly invisible in wide open space, never tilts the view.
- **RotationMagnitude**: strength of the rotational shake. Tilts the camera (pitch/yaw/roll), so it is visible at any distance, can slant the horizon, and throws off the player's aim.
- **Roughness**: how FAST the shake evolves, not how strong it is. Low = slow swaying, high = fast jittering. `0` brings the shake to a standstill and removes rotational shake. Positional noise freezes at its current offset until the roughness changes or the shake stops.
- **TweenSpeed**: how many seconds the three values above take to blend to their new targets when `SetValue` is called. Set to `0` to apply instantly.

Example:

```lua
ShakeSystem:SetValue(1, 2, 3, 0.5)
```

### 4. Start the Shake

```lua
ShakeSystem:Start()
```

### 5. Stop the Shake

```lua
ShakeSystem:Stop()
```

## Advanced Usage

You can pass `nil` for any value you don't want to modify.

For example, to modify only `RotationMagnitude` and `Roughness`:

```lua
ShakeSystem:SetValue(nil, 2, 3, 0)
```

## Distance-based Shakes

You can make the shake fade with distance from a part.

The first parameter is the part, and the second parameter is the range in studs:

```lua
ShakeSystem:SetProximityPart(Part, 20)
```

The shake is full strength at the part and fades linearly to zero at the given range.

Without a proximity part, shakes play at full strength everywhere.

## Rotation Bias

**NEW!!**

By default `RotationMagnitude` shakes pitch, yaw and roll evenly.

You can weight each axis independently to change the "shape" of the rotational shake.

Two ways to call it:

```lua
ShakeSystem:SetRotationBias(Vector3.new(PitchWeight, YawWeight, RollWeight), TweenSpeed)
```

```lua
ShakeSystem:SetRotationBias(PitchWeight, YawWeight, RollWeight, TweenSpeed)
```

- **PitchWeight / YawWeight / RollWeight (X/Y/Z)**: multipliers on that axis's share of `RotationMagnitude`.
  - `1` = normal strength
  - `0` = no shake on that axis
  - `>1` = exaggerated
  - Defaults to `(1, 1, 1)`
- **TweenSpeed**: seconds to blend to the new weights, same as `SetValue`'s `TweenSpeed`.

With the 3-number form, not the `Vector3` form, you can pass `nil` for any axis to leave it unchanged.

Example, roll-biased "concussion" feel with screen tilt and minimal pitch/yaw wobble:

```lua
ShakeSystem:SetRotationBias(Vector3.new(0.15, 0.15, 1), 0.3)
```

Restore the default even all-axis feel:

```lua
ShakeSystem:SetRotationBias(Vector3.new(1, 1, 1), 0.3)
```

## Notes

- `PositionMagnitude` (`A1`, formerly `LShake`) moves the camera without turning it.
- `RotationMagnitude` (`A2`, formerly `AShake`) turns the camera without moving it.
- `Roughness` (`A3`, formerly `Severity`) sets the shake's speed. The magnitudes set its strength.
- Big impacts such as explosions and hits usually look best with a mix of both magnitudes.
- `RotationBias` reshapes rotational shake toward specific axes, for example mostly roll for a dizzy feel.
- Set `ShakeModule.GlobalShake = false` on a client to mute all shakes locally. This is useful for a "camera shake off" toggle in your settings menu.
- Shakes are disabled in VR unless `AllowVRHeadsetCompatibility` is enabled below. This is not recommended.

## Example

```lua
ShakeSystem:SetValue(1, 2, 3, 0.5)
ShakeSystem:Start()
```

## Cleanup

When done with a Shake system, destroy it using `:Remove()`.

**This is required on BOTH server and client.**

This prevents unnecessary instances and connections from piling up.

`ShakeModule.KillAll()` removes every live shake system at once.

Example:

```lua
ShakeSystem:Remove()
```

## Dependency

Direct dependency and camera-noise engine:

**Sleitnick/RbxCameraShaker**  
https://github.com/Sleitnick/RbxCameraShaker

RbxCameraShaker is a Roblox port of EZ Camera Shake by Road Turtle Games.
