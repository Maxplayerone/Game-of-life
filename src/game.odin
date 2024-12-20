package game

import "core:fmt"
import "core:mem"
import rl "vendor:raylib"

_ :: fmt

Width :: 1280
Height :: 720

CellSize :: 16

GridWidth :: Width / CellSize
GridHeight :: Height / CellSize

GridSize :: GridWidth * GridHeight

Game_Memory :: struct {
	//grid:         [GridSize]Cell,
	//back_grid:    [GridSize]Cell,
	//idx:          int,
	grid:               [dynamic]rl.Vector2,
	tracking_allocator: mem.Tracking_Allocator,
	time_btw_gen:       Cycle,
	camera:             rl.Camera2D,
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

camera_moved_cells_offset :: proc(
	camera: rl.Camera2D,
	cell_size: f32,
	start_target := rl.Vector2{0.0, 0.0},
) -> (
	int,
	int,
) {
	x := int(camera.target.x / cell_size)
	y := int(camera.target.y / cell_size)
	return x, y
}

clamp_floor :: proc(v: rl.Vector2, val: f32) -> rl.Vector2 {
	v := v
	offset: rl.Vector2
	if v.x < 0.0 {
		offset.x = val
	}
	if v.y < 0.0 {
		offset.y = val
	}
	v.x -= f32(int(v.x) % int(val)) + offset.x
	v.y -= f32(int(v.y) % int(val)) + offset.y
	return v
}

g_mem: ^Game_Memory

@(export)
game_init_window :: proc() {
	rl.InitWindow(1280, 720, "finite life")
	rl.SetWindowPosition(100, 100)
	rl.SetTargetFPS(60)
}

@(export)
game_init :: proc() {
	g_mem = new(Game_Memory)
	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, context.allocator)
	context.allocator = mem.tracking_allocator(&tracking_allocator)

	g_mem^ = Game_Memory {
		camera = rl.Camera2D{zoom = 1.0},
		tracking_allocator = tracking_allocator,
	}

	g_mem.time_btw_gen = create_cycle(0.1)

	game_hot_reloaded(g_mem)
}

@(export)
game_update :: proc() -> bool {
	dt := rl.GetFrameTime()
	speed: f32 = 700

	//descreate_timesteps := false

	if rl.IsKeyDown(.W) {
		g_mem.camera.target.y -= speed * dt
	}
	if rl.IsKeyDown(.S) {
		g_mem.camera.target.y += speed * dt
	}
	if rl.IsKeyDown(.A) {
		g_mem.camera.target.x -= speed * dt
	}
	if rl.IsKeyDown(.D) {
		g_mem.camera.target.x += speed * dt
	}

	/*
	if descreate_timesteps {
		if rl.IsKeyPressed(.U) && update_cycle(&g_mem.time_btw_gen, dt) {
			g_mem.back_grid = g_mem.grid
			for i in 0 ..< GridSize {
				g_mem.back_grid[i] = step(g_mem.grid[i], get_nb_count(i, g_mem.grid))
			}
			g_mem.grid = g_mem.back_grid
		}
	} else {
		if update_cycle(&g_mem.time_btw_gen, dt) {
			g_mem.back_grid = g_mem.grid
			for i in 0 ..< GridSize {
				g_mem.back_grid[i] = step(g_mem.grid[i], get_nb_count(i, g_mem.grid))
			}
			g_mem.grid = g_mem.back_grid
		}
	}
	*/

	if rl.IsMouseButtonPressed(.LEFT) {
		mouse_world := rl.GetScreenToWorld2D(rl.GetMousePosition(), g_mem.camera)
		append(&g_mem.grid, clamp_floor(mouse_world, CellSize))
	}

	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	rl.BeginMode2D(g_mem.camera)

	//grid
	line_color := rl.Color{255, 255, 255, 125}
	x, y := camera_moved_cells_offset(g_mem.camera, CellSize)
	for i in x ..< GridWidth + x {
		rl.DrawLineEx(
			{CellSize * f32(i), f32(y) * CellSize},
			{CellSize * f32(i), f32(y) * CellSize + Height},
			1.0,
			line_color,
		)
	}
	//horizontal lines
	for i in y ..< GridHeight + y {
		rl.DrawLineEx(
			{f32(x) * CellSize, CellSize * f32(i)},
			{f32(x) * CellSize + Width, CellSize * f32(i)},
			1.0,
			line_color,
		)
	}

	//cells
	rl.DrawRectangleRec({Width / 2 - 50, Height / 2 - 50, 100, 100}, rl.WHITE)
	for cell in g_mem.grid {
		rl.DrawRectangleRec({cell.x, cell.y, CellSize, CellSize}, rl.WHITE)
	}

	rl.EndMode2D()

	rl.EndDrawing()
	free_all(context.temp_allocator)

	return !rl.WindowShouldClose()
}

@(export)
game_shutdown :: proc() {
	delete(g_mem.grid)
	free(g_mem)

	for _, value in g_mem.tracking_allocator.allocation_map {
		fmt.printf("%v: Leaked %v bytes\n", value.location, value.size)
	}
	free_all(context.temp_allocator)
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
