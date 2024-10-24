package game

import "core:fmt"
import rl "vendor:raylib"

_ :: fmt

Width :: 1280
Height :: 720

CellSize :: 16

GridWidth :: Width / CellSize
GridHeight :: Height / CellSize

GridSize :: GridWidth * GridHeight

Game_Memory :: struct {
	grid: [GridSize]Cell,
	idx:  int,
}

Cell :: struct {
	color: rl.Color,
}

step :: proc(cell: ^Cell, neighbours: [8]int) {

}

get_neighbours :: proc(idx: int) -> [8]int {
	//top-tr-right-br-bottom-bl-left-tl
	top := (idx - GridWidth) < 0 ? -1 : idx - GridWidth
	right := (idx + 1) % GridWidth == 0 ? -1 : idx + 1
	bottom := (idx + GridWidth) > GridSize ? -1 : idx + GridWidth
	left := idx % GridWidth == 0 ? -1 : idx - 1

	tr := top != -1 && right != -1 ? idx - GridWidth + 1 : -1
	br := bottom != -1 && right != -1 ? idx + GridWidth + 1 : -1
	bl := bottom != -1 && left != -1 ? idx + GridWidth - 1 : -1
	tl := top != -1 && left != -1 ? idx - GridWidth - 1 : -1

	return {top, tr, right, br, bottom, bl, left, tl}
}

g_mem: ^Game_Memory

grid_index_to_pos :: proc(idx: int) -> rl.Vector2 {
	return grid_index_to_cell_pos(idx) * CellSize
}

grid_index_to_cell_pos :: proc(idx: int) -> rl.Vector2 {
	x := idx % GridWidth
	y := idx / GridWidth

	return rl.Vector2{f32(x), f32(y)}
}

@(export)
game_init_window :: proc() {
	rl.InitWindow(1280, 720, "Game of life")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(500)
}

@(export)
game_init :: proc() {
	g_mem = new(Game_Memory)

	g_mem^ = Game_Memory {
		idx = 1800,
	}

	for i in 0 ..< GridSize {
		g_mem.grid[i].color = rl.BLACK
	}

	g_mem.grid[g_mem.idx].color = rl.WHITE

	game_hot_reloaded(g_mem)
}

@(export)
game_update :: proc() -> bool {

	if rl.IsKeyPressed(.L) {
		g_mem.idx += 1
	}

	if rl.IsKeyPressed(.J) {
		g_mem.idx -= 1
	}

	if rl.IsKeyPressed(.D) {
		g_mem.idx += 100
	}

	if rl.IsKeyPressed(.A) {
		g_mem.idx -= 100
	}

	if rl.IsKeyPressed(.K) {
		g_mem.idx += GridWidth
	}

	if rl.IsKeyPressed(.I) {
		g_mem.idx -= GridWidth
	}

	if rl.IsKeyPressed(.S) {
		g_mem.idx += GridWidth * 10
	}

	if rl.IsKeyPressed(.W) {
		g_mem.idx -= GridWidth * 10
	}


	//reset
	for i in 0 ..< GridSize {
		g_mem.grid[i].color = rl.BLACK
	}

	g_mem.grid[g_mem.idx].color = rl.WHITE

	neighbours := get_neighbours(g_mem.idx)
	for neighbour, i in neighbours {
		if neighbour == -1 {
			fmt.println("bad neighbour ", i)
			continue
		}
		g_mem.grid[neighbour].color = rl.RED
	}

	rl.BeginDrawing()
	rl.ClearBackground(rl.Color{200, 200, 200, 255})

	x := 0
	y := 0
	for i in 0 ..< GridSize {
		x = i % GridWidth
		y = int(i / GridWidth)

		rect := rl.Rectangle{f32(x * CellSize), f32(y * CellSize), CellSize, CellSize}
		rl.DrawRectangleRec(rect, g_mem.grid[i].color)
	}

	rl.EndDrawing()

	return !rl.WindowShouldClose()
}

@(export)
game_shutdown :: proc() {
	free(g_mem)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g_mem
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g_mem = (^Game_Memory)(mem)
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.Z)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.Q)
}
