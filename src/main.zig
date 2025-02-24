const std = @import("std");
const raylib = @import("raylib");
const Color = raylib.Color;

const windowWidth: i32 = 600;
const windowHeight: i32 = 600;
const windowTitle: [:0]const u8 = "Snake";

const gameTilesX: i16 = 20;
const gameTilesY: i16 = 20;
const gameSpacingX: i16 = 20;
const gameSpacingY: i16 = 20;

const groundColorA: Color = .{
    .r = 100,
    .g = 100,
    .b = 100,
    .a = 255,
};

const groundColorB: Color = .{
    .r = 120,
    .g = 120,
    .b = 120,
    .a = 255,
};

const gameTileSizeX = (windowWidth - (gameSpacingX * 2)) / gameTilesX;
const gameTileSizeY = (windowWidth - (gameSpacingY * 2)) / gameTilesY;

const Direction = enum { north, east, south, west };

pub fn main() !void {
    raylib.initWindow(windowWidth, windowHeight, windowTitle);
    raylib.setTargetFPS(2);

    const snakeHead: struct { i32, i32 } = .{ gameTilesX / 2, gameTilesY / 2 };
    _ = snakeHead;
    const snakeDirection: Direction = Direction.north;
    _ = snakeDirection;

    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();

        raylib.clearBackground(Color.black);

        for (0..gameTilesX) |x| {
            for (0..gameTilesY) |y| {
                raylib.drawRectangle(@intCast(gameSpacingX + gameTileSizeX * x), @intCast(gameSpacingY + gameTileSizeY * y), gameTileSizeX, gameTileSizeY, if ((x + y) % 2 == 0) groundColorA else groundColorB);
            }
        }

        raylib.endDrawing();
    }
}
