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

const snakeHeadColor: Color = .{
    .r = 50,
    .g = 50,
    .b = 180,
    .a = 255,
};

const gameTileSizeX = (windowWidth - (gameSpacingX * 2)) / gameTilesX;
const gameTileSizeY = (windowWidth - (gameSpacingY * 2)) / gameTilesY;

const Direction = enum { north, east, south, west };
const Position = struct { x: i32, y: i32 };

pub fn main() !void {
    raylib.initWindow(windowWidth, windowHeight, windowTitle);
    raylib.setTargetFPS(2);

    var snakeHead: Position = .{ .x = gameTilesX / 2, .y = gameTilesY / 2 };
    const snakeDirection: Direction = Direction.north;

    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();

        raylib.clearBackground(Color.black);

        for (0..gameTilesX) |x| {
            for (0..gameTilesY) |y| {
                var color: Color = if ((x + y) % 2 == 0) groundColorA else groundColorB;
                if (x == snakeHead.x and y == snakeHead.y) {
                    color = snakeHeadColor;
                }
                raylib.drawRectangle(@intCast(gameSpacingX + gameTileSizeX * x), @intCast(gameSpacingY + gameTileSizeY * y), gameTileSizeX, gameTileSizeY, color);
            }
        }

        const newPos = torwards(snakeHead, snakeDirection);
        if (newPos.x >= 0 and newPos.x < gameTilesX and newPos.y >= 0 and newPos.y < gameTilesY) {
            snakeHead = newPos;
        }

        raylib.endDrawing();
    }
}

fn torwards(position: Position, direction: Direction) Position {
    var newPos: Position = position;
    switch (direction) {
        Direction.north => {
            newPos.y -= 1;
        },
        Direction.east => {
            newPos.x += 1;
        },
        Direction.south => {
            newPos.y += 1;
        },
        Direction.west => {
            newPos.x -= 1;
        },
    }
    return newPos;
}
