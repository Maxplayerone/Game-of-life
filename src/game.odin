package game

import "core:fmt"
import "core:os"
import "core:strings"
import rl "vendor:raylib"

_ :: fmt

Width :: 1280
Height :: 720

CellSize :: 16

GridWidth :: Width / CellSize
GridHeight :: Height / CellSize

GridSize :: GridWidth * GridHeight

Game_Memory :: struct {
	grid:              [GridSize]Cell,
	back_grid:         [GridSize]Cell,
	idx:               int,
	time_btw_gen:      Cycle,
	scene:             Scene,
	play_button:       rl.Rectangle,
	play_button_color: rl.Color,
}

Scene :: enum {
	Game,
	Menu,
}

Cell :: struct {
	alive: bool,
}

step :: proc(cell: Cell, nb_count: int) -> Cell {
	cell := cell
	if nb_count < 2 {
		cell.alive = false
	}
	if nb_count > 3 && cell.alive {
		cell.alive = false
	}
	if nb_count == 3 && !cell.alive {
		cell.alive = true
	}
	return cell
}

get_nb_count :: proc(i: int, grid: [GridSize]Cell) -> int {
	nbs := get_neighbours(i)
	nb_count := 0
	for nb in nbs {
		if nb != -1 && grid[nb].alive == true {
			nb_count += 1
		}
	}
	return nb_count
}

get_neighbours :: proc(idx: int) -> [8]int {
	//top-tr-right-br-bottom-bl-left-tl
	top := (idx - GridWidth) < 0 ? -1 : idx - GridWidth
	right := (idx + 1) % GridWidth == 0 ? -1 : idx + 1
	bottom := (idx + GridWidth) >= GridSize ? -1 : idx + GridWidth
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

import_pattern :: proc(grid: ^[GridSize]Cell, filepath := "patterns/glider.cells") {
	data, ok := os.read_entire_file(filepath, context.temp_allocator)
	if !ok {
		fmt.println("Could not read file ", filepath)
		return
	}

	it := string(data)
	for line in strings.split_lines_iterator(&it) {
		fmt.println(line)
	}
}

@(export)
game_init_window :: proc() {
	rl.InitWindow(1280, 720, "finite life")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(60)
}

@(export)
game_init :: proc() {
	g_mem = new(Game_Memory)

	g_mem^ = Game_Memory {
		idx = 1800,
	}

	//middle
	g_mem.grid[g_mem.idx].alive = true
	g_mem.grid[g_mem.idx - 1].alive = true
	g_mem.grid[g_mem.idx - GridWidth].alive = true
	g_mem.grid[g_mem.idx + GridWidth].alive = true
	g_mem.grid[g_mem.idx + GridWidth + 1].alive = true

	g_mem.time_btw_gen = create_cycle(0.1)
	g_mem.scene = .Menu
	g_mem.play_button = {Width / 2 - 100, Height / 2 + 50, 200, 50}

	game_hot_reloaded(g_mem)

	import_pattern(&g_mem.grid)
}

@(export)
game_update :: proc() -> bool {
	dt := rl.GetFrameTime()

	//updating
	switch g_mem.scene {
	case .Menu:
		if collission_mouse_rect(g_mem.play_button) {
			g_mem.play_button_color = rl.GRAY
			if rl.IsMouseButtonPressed(.LEFT) {
				g_mem.scene = .Game
			}
		} else {
			g_mem.play_button_color = rl.WHITE
		}
	case .Game:
		if update_cycle(&g_mem.time_btw_gen, dt) {
			g_mem.back_grid = g_mem.grid
			for i in 0 ..< GridSize {
				g_mem.back_grid[i] = step(g_mem.grid[i], get_nb_count(i, g_mem.grid))
			}
			g_mem.grid = g_mem.back_grid
		}
	}

	//rendering
	switch g_mem.scene {
	case .Menu:
		//rendering the game at the back
		x := 0
		y := 0
		for i in 0 ..< GridSize {
			x = i % GridWidth
			y = int(i / GridWidth)

			rect := rl.Rectangle{f32(x * CellSize), f32(y * CellSize), CellSize, CellSize}
			color := g_mem.grid[i].alive ? rl.WHITE : rl.BLACK

			rl.DrawRectangleRec(rect, color)
		}

		rl.DrawRectangleRec({0.0, 0.0, Width, Height}, rl.Color{100, 100, 100, 100})
		draw_text("Finite Life", {Width / 2 - 150, 25, 300, 75})
		rl.DrawRectangleRec(g_mem.play_button, g_mem.play_button_color)
	case .Game:
		x := 0
		y := 0
		for i in 0 ..< GridSize {
			x = i % GridWidth
			y = int(i / GridWidth)

			rect := rl.Rectangle{f32(x * CellSize), f32(y * CellSize), CellSize, CellSize}
			color := g_mem.grid[i].alive ? rl.WHITE : rl.BLACK

			rl.DrawRectangleRec(rect, color)
		}
	}

	free_all(context.temp_allocator)
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
