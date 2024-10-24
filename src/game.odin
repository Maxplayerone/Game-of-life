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
}

Cell :: struct {
	color: rl.Color,
}

g_mem: ^Game_Memory

@(export)
game_init_window :: proc() {
	rl.InitWindow(1280, 720, "Game of life")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(500)
}

@(export)
game_init :: proc() {
	g_mem = new(Game_Memory)

	g_mem^ = Game_Memory{}

	for i in 0 ..< GridSize {
		color := rl.WHITE
		if i % 2 == 0 {
			color = rl.BLACK
		}
		if i % 3 == 0 {
			color = rl.ORANGE
		}
		g_mem.grid[i] = Cell{color}
	}

	game_hot_reloaded(g_mem)
}

@(export)
game_update :: proc() -> bool {

	rl.BeginDrawing()
	rl.ClearBackground(rl.Color{200, 200, 200, 255})

	x := 0
	y := 0
	for i in 0 ..< GridSize {
		x = i % GridWidth
		y = int(i / GridWidth)

		rl.DrawRectangleRec(
			{f32(x * CellSize), f32(y * CellSize), CellSize, CellSize},
			g_mem.grid[i].color,
		)
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
