package main

import "core:fmt"

Rotation :: enum {
	Zero,
	Right,
	Two,
	Left,
}

Kick_Offset :: [2]int
Kick_Tests :: [5]Kick_Offset

Transition :: enum {
	Zero_To_Right, // 0
	Zero_To_Left,
	Right_To_Two,
	Right_To_Zero,
	Two_To_Left,
	Two_To_Right,
	Left_To_Zero,
	Left_To_Two,
}


get_transition :: proc(current: int, direction: int) -> Transition {
	if direction == -1 {
		return cast(Transition)(current * 2 + 1)
	} else if direction == 1 {
		return cast(Transition)(current * 2)
	}

	return Transition.Zero_To_Right
}


JLSTZ_KICKS: [Transition]Kick_Tests = {
	.Zero_To_Right = {{0, 0}, {-1, 0}, {-1, +1}, {0, -2}, {-1, -2}},
	.Right_To_Zero = {{0, 0}, {+1, 0}, {+1, -1}, {0, +2}, {+1, +2}},
	.Right_To_Two  = {{0, 0}, {+1, 0}, {+1, -1}, {0, +2}, {+1, +2}},
	.Two_To_Right  = {{0, 0}, {-1, 0}, {-1, +1}, {0, -2}, {-1, -2}},
	.Two_To_Left   = {{0, 0}, {+1, 0}, {+1, +1}, {0, -2}, {+1, -2}},
	.Left_To_Two   = {{0, 0}, {-1, 0}, {-1, -1}, {0, +2}, {-1, +2}},
	.Left_To_Zero  = {{0, 0}, {-1, 0}, {-1, -1}, {0, +2}, {-1, +2}},
	.Zero_To_Left  = {{0, 0}, {+1, 0}, {+1, +1}, {0, -2}, {+1, -2}},
}

I_KICKS: [Transition]Kick_Tests = {
	.Zero_To_Right = {{0, 0}, {-2, 0}, {+1, 0}, {-2, -1}, {+1, +2}},
	.Right_To_Zero = {{0, 0}, {+2, 0}, {-1, 0}, {+2, +1}, {-1, -2}},
	.Right_To_Two  = {{0, 0}, {-1, 0}, {+2, 0}, {-1, +2}, {+2, -1}},
	.Two_To_Right  = {{0, 0}, {+1, 0}, {-2, 0}, {+1, -2}, {-2, +1}},
	.Two_To_Left   = {{0, 0}, {+2, 0}, {-1, 0}, {+2, +1}, {-1, -2}},
	.Left_To_Two   = {{0, 0}, {-2, 0}, {+1, 0}, {-2, -1}, {+1, +2}},
	.Left_To_Zero  = {{0, 0}, {+1, 0}, {-2, 0}, {+1, -2}, {-2, +1}},
	.Zero_To_Left  = {{0, 0}, {-1, 0}, {+2, 0}, {-1, +2}, {+2, -1}},
}

get_wall_kicks :: proc(piece_type: ShapeEnum, transition: Transition) -> Kick_Tests {
	if piece_type == .I {
		return I_KICKS[transition]
	}

	return JLSTZ_KICKS[transition]
}

get_i_kick_transition :: proc(t: Transition) -> Transition {
    switch t {
    case .Zero_To_Right:
        return .Right_To_Two
    case .Right_To_Two:
        return .Two_To_Left
    case .Two_To_Left:
        return .Left_To_Zero
    case .Left_To_Zero:
        return .Zero_To_Right

    case .Zero_To_Left:
        return .Right_To_Zero
    case .Left_To_Two:
        return .Zero_To_Left
    case .Two_To_Right:
        return .Left_To_Two
    case .Right_To_Zero:
        return .Two_To_Right
    }
    return t
}