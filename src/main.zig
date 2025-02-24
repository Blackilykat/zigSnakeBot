const std = @import("std");
const raylib = @import("raylib");
const queue = @import("queue.zig");
const Color = raylib.Color;

const windowWidth: i32 = 600;
const windowHeight: i32 = 600;
const windowTitle: [:0]const u8 = "Snake";

const gameTilesX: i16 = 20;
const gameTilesY: i16 = 20;
const gameSpacingX: i16 = 20;
const gameSpacingY: i16 = 20;

const targetTickTime: f32 = 0.1;

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

const snakeTailColor: Color = .{
    .r = 50,
    .g = 80,
    .b = 140,
    .a = 255,
};

const gameTileSizeX = (windowWidth - (gameSpacingX * 2)) / gameTilesX;
const gameTileSizeY = (windowWidth - (gameSpacingY * 2)) / gameTilesY;

const Direction = enum { north, east, south, west };
const Position = struct { x: i32, y: i32 };
const PositionQueue = queue.Queue(Position);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    raylib.initWindow(windowWidth, windowHeight, windowTitle);
    raylib.setTargetFPS(100);

    var tailLength: i32 = 10;

    var tail = PositionQueue.init(allocator);

    var snakeHead: Position = .{ .x = gameTilesX / 2, .y = gameTilesY / 2 };
    var snakeDirection: Direction = Direction.north;

    var currentTickTime: f32 = 0.0;

    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();

        currentTickTime += raylib.getFrameTime();

        raylib.clearBackground(Color.black);

        for (0..gameTilesX) |x| {
            for (0..gameTilesY) |y| {
                var color: Color = if ((x + y) % 2 == 0) groundColorA else groundColorB;

                if (tail.first != null) {
                    var ptr: ?*PositionQueue.Node = tail.first;
                    while (ptr != null) {
                        if (ptr.?.*.value.x == x and ptr.?.*.value.y == y) {
                            color = snakeTailColor;
                        }
                        ptr = ptr.?.*.next;
                    }
                }

                if (x == snakeHead.x and y == snakeHead.y) {
                    color = snakeHeadColor;
                }
                raylib.drawRectangle(@intCast(gameSpacingX + gameTileSizeX * x), @intCast(gameSpacingY + gameTileSizeY * y), gameTileSizeX, gameTileSizeY, color);
            }
        }

        takeUserInput(&snakeDirection);

        if (currentTickTime > targetTickTime) {
            currentTickTime -= targetTickTime;
            try tickGame(&snakeHead, snakeDirection, &tail, &tailLength);
        }

        raylib.endDrawing();
    }
}

fn tickGame(snakeHead: *Position, snakeDirection: Direction, tail: *queue.Queue(Position), tailLength: *i32) !void {
    const newPos = torwards(snakeHead.*, snakeDirection);
    if (newPos.x >= 0 and newPos.x < gameTilesX and newPos.y >= 0 and newPos.y < gameTilesY) {
        try tail.enqueue(snakeHead.*);
        if (tail.size > tailLength.*) {
            _ = tail.dequeue();
        }
        snakeHead.* = newPos;
    }
}

fn takeUserInput(direction: *Direction) void {
    const Key = raylib.KeyboardKey;
    if (raylib.isKeyDown(Key.w) or raylib.isKeyDown(Key.up)) {
        if (direction.* != Direction.south) {
            direction.* = Direction.north;
        }
    } else if (raylib.isKeyDown(Key.a) or raylib.isKeyDown(Key.left)) {
        if (direction.* != Direction.east) {
            direction.* = Direction.west;
        }
    } else if (raylib.isKeyDown(Key.s) or raylib.isKeyDown(Key.down)) {
        if (direction.* != Direction.north) {
            direction.* = Direction.south;
        }
    } else if (raylib.isKeyDown(Key.d) or raylib.isKeyDown(Key.right)) {
        if (direction.* != Direction.west) {
            direction.* = Direction.east;
        }
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

test "torwards" {
    const testing = std.testing;

    const pos: Position = .{ .x = 10, .y = 20 };

    try testing.expectEqual(Position{ .x = 10, .y = 19 }, torwards(pos, Direction.north));
    try testing.expectEqual(Position{ .x = 10, .y = 21 }, torwards(pos, Direction.south));
    try testing.expectEqual(Position{ .x = 11, .y = 20 }, torwards(pos, Direction.east));
    try testing.expectEqual(Position{ .x = 9, .y = 20 }, torwards(pos, Direction.west));
}

comptime {
    _ = @import("queue.zig");
}
