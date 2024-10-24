package game

import "core:math"
import "core:math/rand"
import "core:strconv"
import "core:strings"
import rl "vendor:raylib"

// rect related utils
collission_mouse_rect :: proc(rect: rl.Rectangle) -> bool {
	pos := rl.GetMousePosition()
	if pos.x > rect.x &&
	   pos.x < rect.x + rect.width &&
	   pos.y > rect.y &&
	   pos.y < rect.y + rect.height {
		return true
	}
	return false
}

rect_right :: proc(rect: rl.Rectangle, size: f32 = 5.0) -> rl.Rectangle {
	return rl.Rectangle{rect.x + rect.width - size, rect.y, size, rect.height}
}

rect_left :: proc(rect: rl.Rectangle, size: f32 = 5.0) -> rl.Rectangle {
	return rl.Rectangle{rect.x, rect.y, size, rect.height}
}

rect_top :: proc(rect: rl.Rectangle, size: f32 = 5.0) -> rl.Rectangle {
	return rl.Rectangle{rect.x, rect.y, rect.width, size}
}

rect_bottom :: proc(rect: rl.Rectangle, size: f32 = 5.0) -> rl.Rectangle {
	return rl.Rectangle{rect.x, rect.y + rect.height - size, rect.width, size}
}

// math related
rotate_point_around_origin :: proc(
	v: rl.Vector2,
	angle: f32,
	origin := rl.Vector2{0.0, 0.0},
) -> rl.Vector2 {
	v := v
	v -= origin
	v = {
		v.x * math.cos(angle) - v.y * math.sin(angle),
		v.y * math.cos(angle) + v.x * math.sin(angle),
	}
	v += origin
	return v
}

to_rad :: proc(deg: f32) -> f32 {
	return deg * 3.1415 / 180.0
}

random :: proc(num: int) -> int {
	return int(rand.int31() % i32(num))
}

// timer related utils
Timer :: struct {
	time:     f32,
	max_time: f32,
	finished: bool,
}

create_timer :: proc(max_time: f32) -> Timer {
	return Timer{time = 0.0, max_time = max_time}
}

reset_timer :: proc(timer: ^Timer) {
	timer.time = 0.0
	timer.finished = false
}

update_timer :: proc(timer: ^Timer, dt: f32) -> bool {
	timer.time += dt
	if timer.time >= timer.max_time {
		timer.finished = true
	}
	return timer.finished
}

time_left :: proc(timer: Timer) -> f32 {
	return timer.max_time - timer.time
}

// text related utils
@(private)
fit_text_in_line :: proc(text: string, scale: int, width: f32, min_scale := 15) -> int {
	text_cstring := strings.clone_to_cstring(text, context.temp_allocator)
	if f32(rl.MeasureText(text_cstring, i32(min_scale))) > width {
		return 1000
	}
	scale := scale
	for scale > min_scale {
		if f32(rl.MeasureText(text_cstring, i32(scale))) < width {
			break
		}
		scale -= 1
	}
	return scale
}

@(private)
fit_text_in_column :: proc(scale: int, height: f32, min_scale: f32 = 15) -> int {
	if f32(scale) < height {
		return scale
	} else if height >= min_scale {
		return int(height)
	} else {
		return 1000
	}
}

@(private)
fit_text_in_rect :: proc(
	text: string,
	dims: rl.Vector2,
	wanted_scale: int,
	min_scale: f32 = 15,
) -> int {
	scale_x := fit_text_in_line(text, wanted_scale, dims.x, int(min_scale))
	scale_y := fit_text_in_column(wanted_scale, dims.y, min_scale)

	if scale_x < scale_y && scale_y != 1000 {
		return scale_x
	} else if scale_y < scale_x && scale_x != 1000 {
		return scale_y
	} else if scale_x == scale_y && scale_x != 1000 {
		return scale_x
	} else {
		return 0
	}
}

draw_text :: proc(
	text: string,
	rect: rl.Rectangle,
	padding: rl.Vector2 = {10.0, 10.0},
	wanted_scale: int = 100,
	color := rl.WHITE,
	center := true,
) {
	scale := fit_text_in_rect(
		text,
		{rect.width - 2 * padding.x, rect.height - 2 * padding.y},
		wanted_scale,
	)

	text_cstring := strings.clone_to_cstring(text, context.temp_allocator)
	text_width := f32(rl.MeasureText(text_cstring, i32(scale)))

	centering_padding := f32(0.0)
	if center {
		centering_padding = f32((rect.width - text_width) / 2)
	}

	if scale != 0 {
		rl.DrawText(
			text_cstring,
			i32(rect.x + padding.x + centering_padding),
			i32(rect.y + padding.y),
			i32(scale),
			color,
		)
	}
}

draw_num_text :: proc(num: int, rect: rl.Rectangle, color := rl.WHITE) {
	buf: [4]byte
	str := strconv.itoa(buf[:], num)
	draw_text(str, rect)
}

// texture related
draw_texture_on_rect :: proc(tex: rl.Texture, rect: rl.Rectangle) {
	scale_x := rect.width / f32(tex.width)
	scale_y := rect.height / f32(tex.height)

	if scale_y < scale_x {
		x := rect.x + (rect.width / 2.0 - f32(tex.width) * scale_y * 0.5)
		rl.DrawTextureEx(tex, {x, rect.y}, 0.0, scale_y, rl.WHITE)
	} else {
		y := rect.y + (rect.height / 2.0 - f32(tex.height) * scale_x * 0.5)
		rl.DrawTextureEx(tex, {rect.x, y}, 0.0, scale_x, rl.WHITE)
	}
}
