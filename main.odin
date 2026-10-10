#+feature using-stmt

package main

import "core:c"
import "core:fmt"
import "core:math/rand"
import "core:mem"
import "core:strings"
import rl "vendor:raylib"

ROW :: 20
COL :: 10
CELL_SIZE :: 20
TICK: f32 : 0.5

DAS: f32 : 0.15
ARR: f32 : 0.04

gamepad_connected := false

ShapeEnum :: enum {
	I,
	S,
	Z,
	T,
	L,
	J,
	O,
}

MoveShapeDir :: enum {
	NONE,
	LEFT,
	RIGHT,
}
InputState :: struct {
	horizontal_das: f32,
	horizontal_arr: f32,
	vertical_arr:   f32,
	direction:      MoveShapeDir,
}


ActivePiece :: struct {
	pos:              [2]int,
	current_rotation: int,
	type:             ShapeEnum,
}

PieceBag :: struct {
	pieces: [7]ShapeEnum,
	next:   int,
}

Game :: struct {
	grid:          [ROW][COL]int,
	bag:           PieceBag,
	active_piece:  ActivePiece,
	next_piece:    ShapeEnum,
	score:         int,
	level:         int,
	lines_cleared: int,
	timer:         f32,
	input_state:   InputState,
}

start_new_game :: proc(game: ^Game) {
	clear_grid(game)
	game.bag = init_bag()
	game.active_piece = spawn_piece(game)
	game.next_piece = game.bag.pieces[game.bag.next]
	game.timer = 0
	game.score = 0
	game.level = 0
	game.lines_cleared = 0
}

update_horizontal_input :: proc(game: ^Game, dt: f32) {
	left_down :=
		rl.IsKeyDown(.LEFT) || (gamepad_connected && rl.IsGamepadButtonDown(0, .LEFT_FACE_LEFT))
	right_down :=
		rl.IsKeyDown(.RIGHT) || (gamepad_connected && rl.IsGamepadButtonDown(0, .LEFT_FACE_RIGHT))

	new_dir := game.input_state.direction

	if rl.IsKeyPressed(.LEFT) ||
	   (gamepad_connected && rl.IsGamepadButtonPressed(0, .LEFT_FACE_LEFT)) {
		new_dir = .LEFT
	} else if rl.IsKeyPressed(.RIGHT) ||
	   (gamepad_connected && rl.IsGamepadButtonPressed(0, .LEFT_FACE_RIGHT)) {
		new_dir = .RIGHT
	} else if game.input_state.direction == .LEFT && !left_down {
		new_dir = right_down ? .RIGHT : .NONE
	} else if game.input_state.direction == .RIGHT && !right_down {
		new_dir = left_down ? .LEFT : .NONE
	}

	if new_dir != game.input_state.direction {
		game.input_state.direction = new_dir
		game.input_state.horizontal_das = 0
		game.input_state.horizontal_arr = 0
		if new_dir != .NONE {
			move_piece_horizontal(game)
		}
	}

	if game.input_state.direction == .NONE {
		return
	}

	game.input_state.horizontal_das += dt
	if game.input_state.horizontal_das >= DAS {
		game.input_state.horizontal_arr += dt
		for game.input_state.horizontal_arr >= ARR {
			move_piece_horizontal(game)
			game.input_state.horizontal_arr -= ARR
		}
	}
}

set_next_piece :: proc(game: ^Game) {
	if game.bag.next == 7 {
		game.next_piece = rand.choice_enum(ShapeEnum)
	} else {
		game.next_piece = game.bag.pieces[game.bag.next]
	}
}

land_piece :: proc(game: ^Game) -> bool {
	if lock_piece(game) {
		return true
	}
	clear_completed_rows(game)
	game.active_piece = spawn_piece(game)
	set_next_piece(game)
	game.timer = 0
	game.input_state.vertical_arr = 0
	return false
}

step_piece_down :: #force_inline proc(game: ^Game) -> bool {
	if move_piece_down(game) {
		return land_piece(game)
	}
	return false
}

update_game :: proc(game: ^Game) -> bool {
	skip_tick := false

	dt := rl.GetFrameTime()
	update_horizontal_input(game, dt)

	if rl.IsKeyPressed(.X) ||
	   (gamepad_connected && rl.IsGamepadButtonPressed(0, .RIGHT_FACE_DOWN)) {
		rotate_piece(game, -1)
	} else if rl.IsKeyPressed(.C) ||
	   (gamepad_connected && rl.IsGamepadButtonPressed(0, .RIGHT_FACE_RIGHT)) {
		rotate_piece(game, 1)
	} else if rl.IsKeyPressed(.UP) {
		skip_tick = true
		for {
			if move_piece_down(game) {
				return land_piece(game)
			}
		}
	}

	if rl.IsKeyDown(rl.KeyboardKey.DOWN) ||
	   (gamepad_connected && rl.IsGamepadButtonDown(0, .LEFT_FACE_DOWN)) {
		skip_tick = true
		game.input_state.vertical_arr += dt
		for game.input_state.vertical_arr >= ARR / 1.5 {
			if step_piece_down(game) {
				return true
			}
			game.input_state.vertical_arr -= ARR / 1.5
		}
	} else {
		game.input_state.vertical_arr = 0
	}

	if game.timer >= TICK && !skip_tick {
		if step_piece_down(game) {
			return true
		}
		game.timer = 0
	}
	game.timer += dt
	return false
}

draw_game :: proc(game: ^Game) {
	rl.ClearBackground(rl.BLACK)
	{ 	// draw grid outlines
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
	}
	draw_locked_pieces(game.grid)
	draw_active_piece(game.active_piece)
	draw_next_pieces(game.next_piece)
	score := strings.clone_to_cstring(fmt.tprintf("%d", game.lines_cleared))
	rl.DrawText(score, 270, 184, 20, rl.WHITE)
	delete_cstring(score)
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

get_next_piece :: proc(game: ^Game) -> ShapeEnum {
	using game
	if bag.next >= len(bag.pieces) {
		rand.shuffle(bag.pieces[:])
		for s, i in bag.pieces {
			if next_piece == s && i > 0 {
				first := bag.pieces[0]
				bag.pieces[0] = next_piece
				bag.pieces[i] = first
			}
		}
		bag.next = 0
	}

	shape := bag.pieces[bag.next]
	bag.next += 1

	return shape
}

draw_active_piece :: proc(piece: ActivePiece) {
	for block in SHAPES[piece.type].rotations[piece.current_rotation] {
		coords := (piece.pos + block) * CELL_SIZE
		rl.DrawRectangle(
			c.int(coords.x + 1),
			c.int(coords.y + 1),
			CELL_SIZE - 2,
			CELL_SIZE - 2,
			get_color(piece.type),
		)
	}
}

move_piece_horizontal :: proc(game: ^Game) {
	candidate := game.active_piece

	_dir := game.input_state.direction == .LEFT ? -1 : game.input_state.direction == .RIGHT ? 1 : 0
	candidate.pos += {_dir, 0}
	if !collides(game, candidate) {
		game.active_piece.pos = candidate.pos
	}
}

move_piece_right :: proc(game: ^Game, dir: MoveShapeDir) {
	candidate := game.active_piece
	candidate.pos += {1, 0}
	if !collides(game, candidate) {
		game.active_piece.pos = candidate.pos
	}
}

move_piece_left :: proc(game: ^Game) {
	candidate := game.active_piece
	candidate.pos += {-1, 0}
	if !collides(game, candidate) {
		game.active_piece.pos = candidate.pos
	}
}

move_piece_down :: proc(game: ^Game) -> bool {
	candidate := game.active_piece
	candidate.pos += {0, 1}

	if !collides(game, candidate) {
		game.active_piece.pos = candidate.pos
	} else {
		return true
	}

	return false
}

rotate_piece :: proc(game: ^Game, dir: int) {
	// old code
	// candidate := game.active_piece
	// num_rotations := len(SHAPES[candidate.type].rotations)

	// candidate.current_rotation =
	// 	(game.active_piece.current_rotation + dir + num_rotations) % num_rotations

	// if !collides(game, candidate) {
	// 	game.active_piece = candidate
	// }

	original := game.active_piece
	transition := get_transition(original.current_rotation, dir)

	if original.type == .O {
		return
	}
	if original.type == .I {
		transition = get_i_kick_transition(transition)
	}
	kicks := get_wall_kicks(original.type, transition)

	for kick, i in kicks {
		candidate := original

		num_rotations := len(SHAPES[candidate.type].rotations)
		candidate.current_rotation =
			(game.active_piece.current_rotation + dir + num_rotations) % num_rotations

		candidate.pos.x += kick.x
		candidate.pos.y -= kick.y

		blocked := collides(game, candidate)

		if !blocked {
			game.active_piece = candidate
			return
		}
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
		return rl.ORANGE
	case .J:
		return rl.BLUE
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

	for p_block, i in SHAPES[piece.type].rotations[piece.current_rotation] {
		block := p_block + piece.pos
		blocks[i] = block
	}
	return blocks
}

collides :: proc(game: ^Game, piece: ActivePiece) -> bool {
	blocks := get_world_blocks(piece)

	for block, i in blocks {
		x := block.x
		y := block.y


		if x < 0 || x >= COL || y >= ROW {
			return true
		}

		if y >= 0 && game.grid[y][x] != 0 {
			return true
		}
	}
	return false
}

draw_next_pieces :: proc(shape: ShapeEnum) {
	rl.DrawText("Next Piece", 240, 40, 20, rl.WHITE)
	for block in SHAPES[shape].rotations[0] {
		offset := [2]int{13, 4}

		if shape == ShapeEnum.I {
			offset.x -= 1
		}
		coords := (offset + block) * CELL_SIZE
		rl.DrawRectangle(c.int(coords.x), c.int(coords.y), CELL_SIZE, CELL_SIZE, get_color(shape))
	}
	// rl.DrawLine("Lines Cleared")
	rl.DrawText("Lines Cleared", 230, 160, 20, rl.WHITE)

}

draw_locked_pieces :: proc(board: [ROW][COL]int) {
	for rows, y in board {
		for cell, x in rows {
			if cell > 0 {
				rl.DrawRectangle(
					c.int(x * CELL_SIZE + 1),
					c.int(y * CELL_SIZE + 1),
					CELL_SIZE - 2,
					CELL_SIZE - 2,
					get_color((ShapeEnum)(cell - 1)),
				)
			}
		}
	}
}

lock_piece :: proc(game: ^Game) -> bool {
	game_over := false

	for block in get_world_blocks(game.active_piece) {

		if block.y < 0 {
			game_over = true
			continue
		}
		game.grid[block.y][block.x] = int(game.active_piece.type) + 1
	}

	return game_over
}

is_row_full :: proc(game: ^Game, y: int) -> bool {
	for cell in game.grid[y] {
		if cell == 0 {return false}
	}
	return true
}

clear_row :: proc(game: ^Game, row: int) {
	for y := row; y > 0; y -= 1 {
		game.grid[y] = game.grid[y - 1]
	}
	game.grid[0] = {}
}

clear_completed_rows :: proc(game: ^Game) {
	y := ROW - 1

	for y >= 0 {
		if is_row_full(game, y) {
			clear_row(game, y)
			game.lines_cleared += 1
		} else {
			y -= 1
		}
	}
}

spawn_piece :: proc(game: ^Game) -> ActivePiece {
	shape_type := get_next_piece(game)
	return ActivePiece{type = shape_type, pos = {4, -2}}
}

clear_grid :: proc(game: ^Game) {
	for x in 0 ..< COL {
		for y in 0 ..< ROW {
			game.grid[y][x] = 0
		}
	}
}

GameState :: enum {
	Start,
	Pause,
	Play,
	GameOver,
}

main :: proc() {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	context.allocator = mem.tracking_allocator(&track)

	defer {
		fmt.println("...Checking unallocated memory...")
		if len(track.allocation_map) > 0 {
			total := 0
			for _, leak in track.allocation_map {
				fmt.eprintf("%v leaked %m\n", leak.location, leak.size)
				total += leak.size
			}
			fmt.eprintf("Total Memory leaked : %m (%d)\n", total, total)
		} else {
			fmt.println("No memory leaks.")
		}

		for addr, location in track.bad_free_array {
			// fmt.printfln("bad free of &v originating at %v", addr, location)
			fmt.printfln("bad free of %v originating at %v", addr, location)
		}
	}


	rl.InitWindow(400, 400, "tetris")
	defer rl.CloseWindow()
	// rl.SetExitKey(.KEY_NULL)
	rl.SetTargetFPS(60)

	gamepad_connected = rl.IsGamepadAvailable(0)
	fmt.println(rl.GetGamepadName(0))
	game_state: GameState

	game: Game

	for !rl.WindowShouldClose() {
		// fmt.println(rl.GetGamepadButtonPressed())
		#partial switch game_state {
		case .Start:
			if rl.IsKeyPressed(.SPACE) ||
			   (gamepad_connected && rl.IsGamepadButtonPressed(0, .RIGHT_FACE_DOWN)) {
				start_new_game(&game)
				game_state = .Play
			}
			rl.BeginDrawing()
			{
				rl.ClearBackground(rl.BLACK)

				rl.DrawText("Press SPACE to start!", 80, 50, 20, rl.WHITE)
			}
			rl.EndDrawing()
		case .Pause, .Play:
			if rl.IsKeyPressed(.SPACE) {
				if game_state == .Play {
					game_state = .Pause
				} else {
					game_state = .Play
				}
			}

			if game_state == .Play {
				if update_game(&game) {
					game_state = .GameOver
				}
			}
			rl.BeginDrawing()

			draw_game(&game)
			if game_state == .Pause {
				rl.DrawText("Paused!", 160, 160, 20, rl.WHITE)
				rl.DrawText("Press SPACE to resume!", 80, 180, 20, rl.WHITE)
			}
			rl.EndDrawing()

		case .GameOver:
			if rl.IsKeyPressed(.SPACE) ||
			   (gamepad_connected && rl.IsGamepadButtonPressed(0, .RIGHT_FACE_DOWN)) {
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
