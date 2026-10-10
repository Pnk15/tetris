# Tetris

A classic falling-block puzzle game implemented in Odin using Raylib.

## Overview

This project is a lightweight Tetris clone with a 10x20 playfield, falling tetrominoes, line clearing, score tracking, level progression, and a next-piece preview. It includes both keyboard and basic gamepad support.

## Features

- Classic Tetris gameplay loop
- Seven tetromino shapes: I, J, L, O, S, T, and Z
- Rotation and wall-kick behavior
- Soft drop and hard drop controls
- Line clearing and scoring counters
- Randomized piece bag generation
- Next-piece preview
- Simple gamepad support

## Controls

### Keyboard

- Left / Right Arrow: move piece horizontally
- Down Arrow: soft drop
- Up Arrow: hard drop
- X: rotate left
- C: rotate right

### Gamepad

- D-pad left/right: move horizontally
- D-pad down: soft drop
- Right face buttons: rotate

## Project Structure

- `main.odin` - main game loop and core gameplay logic
- `shape_def.odin` - tetromino definitions and rotations
- `wall_kick.odin` - wall-kick and collision behavior
- `makefile` - build and run helper commands
- `bin/` - output directory for built binaries

## Requirements

- Odin compiler
- Raylib libraries for Odin
- Windows build setup as defined by the project configuration

## Running the Game

From the project root:

```bash
make run
```

This runs the project with Odin and the configured linker.

## Building

```bash
make build
```

This produces a Windows executable at:

```text
bin/tetris.exe
```

## Debug Build

```bash
make debug-build
```

## Cleaning Output

```bash
make clean
```

## Todo

Planned feature and gameplay improvements:

- [] Hold piece system
- [] Ghost piece preview
- [] Proper game menus (start, pause, game over, restart)
- [] Score and difficulty progression improvements

## Notes

The project is intentionally small and focused, making it a good reference for learning Odin game development with Raylib and basic game systems like gravity, input handling, collision detection, and row clearing.
