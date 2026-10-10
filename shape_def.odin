package main

ShapeDefinition :: struct {
	type:      ShapeEnum,
	rotations: [][4][2]int,
}

Shape_I: ShapeDefinition : {
	rotations = {
		{{2, 0}, {2, 1}, {2, 2}, {2, 3}},
		{{0, 2}, {1, 2}, {2, 2}, {3, 2}},
		{{1, 0}, {1, 1}, {1, 2}, {1, 3}},
		{{0, 1}, {1, 1}, {2, 1}, {3, 1}},
	},
	type = .I,
}

Shape_L: ShapeDefinition : {
	rotations = {
		{{2, 0}, {0, 1}, {1, 1}, {2, 1}},
		{{1, 0}, {1, 1}, {1, 2}, {2, 2}},
		{{0, 2}, {0, 1}, {1, 1}, {2, 1}},
		{{1, 0}, {1, 1}, {1, 2}, {0, 0}},
	},
	type = .L,
}
Shape_J: ShapeDefinition : {
	rotations = {
		{{0, 0}, {0, 1}, {1, 1}, {2, 1}},
		{{2, 0}, {1, 0}, {1, 1}, {1, 2}},
		{{0, 1}, {1, 1}, {2, 1}, {2, 2}},
		{{1, 0}, {1, 1}, {1, 2}, {0, 2}},
	},
	type = .J,
}
Shape_S: ShapeDefinition : {
	rotations = {
		{{2, 0}, {1, 0}, {1, 1}, {0, 1}},
		{{1, 0}, {1, 1}, {2, 1}, {2, 2}},
		{{2, 1}, {1, 1}, {1, 2}, {0, 2}},
		{{0, 0}, {0, 1}, {1, 1}, {1, 2}},
	},
	type = .S,
}
Shape_Z: ShapeDefinition : {
	rotations = {
		{{0, 0}, {1, 0}, {1, 1}, {2, 1}},
		{{2, 0}, {1, 1}, {2, 1}, {1, 2}},
		{{0, 1}, {1, 1}, {1, 2}, {2, 2}},
		{{1, 0}, {1, 1}, {0, 1}, {0, 2}},
	},
	type = .Z,
}

Shape_T: ShapeDefinition : {
	rotations = {
		{{0, 1}, {1, 0}, {1, 1}, {2, 1}},
		{{1, 0}, {1, 1}, {1, 2}, {2, 1}},
		{{0, 1}, {1, 1}, {1, 2}, {2, 1}},
		{{0, 1}, {1, 1}, {1, 0}, {1, 2}},
	},
	type = .T,
}

Shape_O: ShapeDefinition : {rotations = {{{1, 0}, {2, 0}, {1, 1}, {2, 1}}}, type = ShapeEnum.O}

SHAPES := [7]ShapeDefinition {
	ShapeEnum.I = Shape_I,
	ShapeEnum.J = Shape_J,
	ShapeEnum.L = Shape_L,
	ShapeEnum.O = Shape_O,
	ShapeEnum.S = Shape_S,
	ShapeEnum.T = Shape_T,
	ShapeEnum.Z = Shape_Z,
}
