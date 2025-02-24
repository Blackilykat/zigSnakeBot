const std = @import("std");
const raylib = @import("raylib");

pub fn main() !void {
    raylib.initWindow(600, 600, "Hello, world!");
    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();

        raylib.drawCircle(100, 100, 20.0, raylib.Color.red);

        raylib.endDrawing();
    }
}
