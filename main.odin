package main

import "core:c"
import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

ROW :: 20
COL :: 10
CELL_SIZE :: 20
TICK: f32 : 0.5

grid: [ROW][COL]int


ShapeEnum :: enum {
	I,
	S,
	Z,
	T,
	L,
	J,
	O,
}

ShapeDefinition :: struct {
	type:      ShapeEnum,
	rotations: [][4][2]int,
}

ActivePiece :: struct {
	pos:              [2]int,
	current_rotation: int,
	definition:       ^ShapeDefinition,
}

PieceBag :: struct {
	pieces: [7]ShapeEnum,
	next:   int,
}

init_bag :: proc() -> PieceBag {
	bag := PieceBag {
		next = 0,
	}

	for shape_enum, i in ShapeEnum {
		bag.pieces[i] = shape_enum
	}

	rand.shuffle(bag.pieces[:])

	return bag
}

get_next_piece :: proc(bag: ^PieceBag) -> ShapeEnum {
	if bag.next >= len(bag.pieces) {
		rand.shuffle(bag.pieces[:])
		bag.next = 0
	}

	shape := bag.pieces[bag.next]
	bag.next += 1

	return shape
}


draw_active_piece :: proc(piece: ActivePiece) {
	for block in piece.definition.rotations[piece.current_rotation] {
		coords := (piece.pos + block) * CELL_SIZE
		rl.DrawRectangle(
			c.int(coords.x),
			c.int(coords.y),
			CELL_SIZE,
			CELL_SIZE,
			get_color(piece.definition.type),
		)
	}
}

move_piece_right :: proc(piece: ^ActivePiece) {
	candidate := piece^
	candidate.pos += {1, 0}
	if !collides(candidate) {
		piece.pos = candidate.pos
	}
}

move_piece_left :: proc(piece: ^ActivePiece) {
	candidate := piece^
	candidate.pos += {-1, 0}
	if !collides(candidate) {
		piece.pos = candidate.pos
	}
}

move_piece_down :: proc(piece: ^ActivePiece) -> bool {
	candidate := piece^
	candidate.pos += {0, 1}

	if !collides(candidate) {
		piece.pos = candidate.pos
	} else {
		return true
	}

	return false
}

rotate_piece :: proc(piece: ^ActivePiece, dir: int) {
	candidate := piece^

	num_rotations := len(candidate.definition.rotations)
	candidate.current_rotation = (piece.current_rotation + dir + num_rotations) % num_rotations

	if !collides(candidate) {
		piece^ = candidate
	}
}

get_color :: proc(shape_kind: ShapeEnum) -> rl.Color {
	switch shape_kind {
	case .I:
		return rl.SKYBLUE
	case .S:
		return rl.GREEN
	case .Z:
		return rl.RED
	case .L:
		return rl.BLUE
	case .J:
		return rl.ORANGE
	case .O:
		return rl.YELLOW
	case .T:
		return rl.MAGENTA
	case:
		return rl.WHITE
	}
}

get_world_blocks :: proc(piece: ActivePiece) -> [4][2]int {
	blocks: [4][2]int
	for p_block, i in piece.definition.rotations[piece.current_rotation] {
		block := p_block + piece.pos
		blocks[i] = block
	}
	return blocks
}

collides :: proc(piece: ActivePiece) -> bool {
	blocks := get_world_blocks(piece)
	for block, i in blocks {
		x := block.x
		y := block.y


		if x < 0 {return true}
		if x >= COL {return true}
		if y >= ROW {return true}

		if y >= 0 && grid[y][x] != 0 {
			return true
		}
	}
	return false
}


draw_grid :: proc(board: [ROW][COL]int) {
	for rows, y in board {
		for cell, x in rows {
			if cell > 0 {
				rl.DrawRectangle(
					c.int(x * CELL_SIZE),
					c.int(y * CELL_SIZE),
					CELL_SIZE,
					CELL_SIZE,
					get_color((ShapeEnum)(cell - 1)),
				)
			}
		}
	}
}

lock_piece :: proc(piece: ActivePiece) -> bool {
	game_over := false

	for block in get_world_blocks(piece) {

		if block.y < 0 {
			game_over = true
			continue
		}

		grid[block.y][block.x] = int(piece.definition.type) + 1
	}

	return game_over
}

is_row_full :: proc(y: int) -> bool {
	for cell in grid[y] {
		if cell == 0 {return false}
	}
	return true
}

clear_row :: proc(row: int) {
	for y := row; y > 0; y -= 1 {
		grid[y] = grid[y - 1]
	}
	grid[0] = {}
}

clear_completed_rows :: proc() {
	y := ROW - 1

	for y >= 0 {
		if is_row_full(y) {
			clear_row(y)
		} else {
			y -= 1
		}
	}
}

spawn_piece :: proc(shapes: ^[len(ShapeEnum)]ShapeDefinition, bag: ^PieceBag) -> ActivePiece {

	shape_type := get_next_piece(bag)

	return ActivePiece{definition = &shapes[shape_type], pos = {4, -2}}
}


clear_grid :: proc() {
	for x in 0 ..< COL {
		for y in 0 ..< ROW {
			grid[y][x] = 0
		}
	}
}
game_over := false

GameState :: enum {
	Start,
	Pause,
	Play,
	GameOver,
}


main :: proc() {


	rl.InitWindow(400, 400, "tetris")
	defer rl.CloseWindow()
	rl.SetExitKey(.KEY_NULL)
	rl.SetTargetFPS(60)

	timer: f32
	game_state: GameState

	Shape_I: ShapeDefinition = {
		rotations = {
			{{2, 0}, {2, 1}, {2, 2}, {2, 3}},
			{{0, 2}, {1, 2}, {2, 2}, {3, 2}},
			{{1, 0}, {1, 1}, {1, 2}, {1, 3}},
			{{0, 1}, {1, 1}, {2, 1}, {3, 1}},
		},
		type      = .I,
	}

	Shape_L: ShapeDefinition = {
		rotations = {
			{{0, 0}, {0, 1}, {1, 1}, {2, 1}},
			{{2, 0}, {1, 0}, {1, 1}, {1, 2}},
			{{0, 1}, {1, 1}, {2, 1}, {2, 2}},
			{{1, 0}, {1, 1}, {1, 2}, {0, 2}},
		},
		type      = .L,
	}
	Shape_J: ShapeDefinition = {
		rotations = {
			{{2, 0}, {0, 1}, {1, 1}, {2, 1}},
			{{1, 0}, {1, 1}, {1, 2}, {2, 2}},
			{{0, 2}, {0, 1}, {1, 1}, {2, 1}},
			{{1, 0}, {1, 1}, {1, 2}, {0, 0}},
		},
		type      = .J,
	}
	Shape_S: ShapeDefinition = {
		rotations = {
			{{2, 0}, {1, 0}, {1, 1}, {0, 1}},
			{{1, 0}, {1, 1}, {2, 1}, {2, 2}},
			{{2, 1}, {1, 1}, {1, 2}, {0, 2}},
			{{0, 0}, {0, 1}, {1, 1}, {1, 2}},
		},
		type      = .S,
	}
	Shape_Z: ShapeDefinition = {
		rotations = {
			{{0, 0}, {1, 0}, {1, 1}, {2, 1}},
			{{2, 0}, {1, 1}, {2, 1}, {1, 2}},
			{{0, 1}, {1, 1}, {1, 2}, {2, 2}},
			{{1, 0}, {1, 1}, {0, 1}, {0, 2}},
		},
		type      = .Z,
	}

	Shape_T: ShapeDefinition = {
		rotations = {
			{{0, 1}, {1, 0}, {1, 1}, {2, 1}},
			{{1, 0}, {1, 1}, {1, 2}, {2, 1}},
			{{0, 1}, {1, 1}, {1, 2}, {2, 1}},
			{{0, 1}, {1, 1}, {1, 0}, {1, 2}},
		},
		type      = .T,
	}

	Shape_O: ShapeDefinition = {
		rotations = {{{1, 0}, {2, 0}, {1, 1}, {2, 1}}},
		type      = ShapeEnum.O,
	}

	SHAPES := [len(ShapeEnum)]ShapeDefinition {
		ShapeEnum.I = Shape_I,
		ShapeEnum.J = Shape_J,
		ShapeEnum.L = Shape_L,
		ShapeEnum.O = Shape_O,
		ShapeEnum.S = Shape_S,
		ShapeEnum.T = Shape_T,
		ShapeEnum.Z = Shape_Z,
	}

	bag: PieceBag
	active_piece: ActivePiece

	for !rl.WindowShouldClose() {

		#partial switch game_state {
		case .Start:
			if rl.IsKeyPressed(.SPACE) {
				clear_grid()
				bag := init_bag()
				active_piece = spawn_piece(&SHAPES, &bag)
				timer = 0
				game_state = .Play
			}
			rl.BeginDrawing()
			{
				rl.ClearBackground(rl.BLACK)

				rl.DrawText("Press SPACE to start!", 80, 50, 20, rl.WHITE)
			}
			rl.EndDrawing()
		case .Pause:
		case .Play:
			if rl.IsKeyPressed(rl.KeyboardKey.LEFT) {
				move_piece_left(&active_piece)
			} else if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) {
				move_piece_right(&active_piece)
			}

			if rl.IsKeyPressed(rl.KeyboardKey.X) {
				rotate_piece(&active_piece, -1)
			} else if rl.IsKeyPressed(rl.KeyboardKey.C) {
				rotate_piece(&active_piece, 1)
			}

			if rl.IsKeyDown(rl.KeyboardKey.DOWN) {
				move_piece_down(&active_piece)
			}

			if timer > TICK {
				should_lock := move_piece_down(&active_piece)
				if should_lock {
					game_over := lock_piece(active_piece)
					if game_over {
						game_state = .GameOver
						continue
					}
					clear_completed_rows()

					random_shape_type := rand.choice_enum(ShapeEnum)
					active_piece = spawn_piece(&SHAPES, &bag)
				}
				timer = 0
			}
			rl.BeginDrawing()
			{
				rl.ClearBackground(rl.BLACK)


				for x in 0 ..< COL {
					for y in 0 ..< ROW {
						rl.DrawRectangleLines(
							c.int(x * CELL_SIZE),
							c.int(y * CELL_SIZE),
							CELL_SIZE,
							CELL_SIZE,
							{255, 255, 255, 20},
						)
					}
				}
				draw_grid(grid)
				draw_active_piece(active_piece)
			}
			rl.EndDrawing()
			timer += rl.GetFrameTime()
		case .GameOver:
			if rl.IsKeyPressed(.SPACE) {

				game_state = .Start
				continue
			}

			rl.BeginDrawing()
			{
				rl.ClearBackground(rl.BLACK)
				rl.DrawText("Game Over!", 140, 20, 20, rl.RED)
				rl.DrawText("Press SPACE to start!", 80, 50, 20, rl.WHITE)
			}
			rl.EndDrawing()

		}
	}
}
