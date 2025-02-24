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

const appleColor: Color = .{
    .r = 255,
    .g = 50,
    .b = 50,
    .a = 255,
};

const deathText = "Game over!";
const deathTextSize = 60;
const deathRestartText = "Press space to restart";
const deathRestartSize = 30;
const deathRestartOffset = 100;
const deathTextColor: Color = .{
    .r = 240,
    .g = 60,
    .b = 60,
    .a = 255,
};

const gameTileSizeX = (windowWidth - (gameSpacingX * 2)) / gameTilesX;
const gameTileSizeY = (windowWidth - (gameSpacingY * 2)) / gameTilesY;

const Direction = enum { north, east, south, west };
const Position = struct { x: i32 = 0, y: i32 = 0 };
const PositionQueue = queue.Queue(Position);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    raylib.initWindow(windowWidth, windowHeight, windowTitle);
    raylib.setTargetFPS(100);

    var tailLength: i32 = 0;

    var tail = PositionQueue.init(allocator);

    var snakeHead: Position = .{};
    var snakeDirection: Direction = Direction.north;
    var oldSnakeDirection: Direction = Direction.north;

    var currentTickTime: f32 = 0.0;

    var isGameOngoing = false;

    var apple: Position = .{};

    try resetGame(allocator, &snakeHead, &snakeDirection, &tail, &tailLength, &isGameOngoing, &apple);

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

                if (x == apple.x and y == apple.y) {
                    color = appleColor;
                }

                if (x == snakeHead.x and y == snakeHead.y) {
                    color = snakeHeadColor;
                }
                raylib.drawRectangle(@intCast(gameSpacingX + gameTileSizeX * x), @intCast(gameSpacingY + gameTileSizeY * y), gameTileSizeX, gameTileSizeY, color);
            }
        }

        if (!isGameOngoing) {
            {
                const textWidth = raylib.measureText(deathText, deathTextSize);
                raylib.drawText(deathText, @divFloor(windowWidth, 2) - @divFloor(textWidth, 2), @divFloor(windowHeight, 2) - @divFloor(deathTextSize, 2), deathTextSize, deathTextColor);
            }
            {
                const textWidth = raylib.measureText(deathRestartText, deathRestartSize);
                raylib.drawText(deathRestartText, @divFloor(windowWidth, 2) - @divFloor(textWidth, 2), @divFloor(windowHeight, 2) - @divFloor(deathRestartSize, 2) + deathRestartOffset, deathRestartSize, deathTextColor);
            }

            if (raylib.isKeyPressed(raylib.KeyboardKey.space)) {
                try resetGame(allocator, &snakeHead, &snakeDirection, &tail, &tailLength, &isGameOngoing, &apple);
            }
        }

        takeUserInput(&snakeDirection, oldSnakeDirection);

        if (currentTickTime > targetTickTime) {
            currentTickTime -= targetTickTime;
            if (isGameOngoing) {
                try tickGame(allocator, &snakeHead, snakeDirection, &tail, &tailLength, &isGameOngoing, &apple);
                oldSnakeDirection = snakeDirection;
            }
        }

        raylib.endDrawing();
    }
}

fn resetGame(allocator: std.mem.Allocator, snakeHead: *Position, snakeDirection: *Direction, tail: *PositionQueue, tailLength: *i32, isGameOngoing: *bool, apple: *Position) !void {
    snakeHead.* = .{ .x = gameTilesX / 2, .y = gameTilesY / 2 };
    snakeDirection.* = Direction.north;
    tail.deinit();
    tail.* = PositionQueue.init(allocator);
    tailLength.* = 1;
    try moveApple(allocator, snakeHead.*, tail, apple);
    isGameOngoing.* = true;
}

fn tickGame(allocator: std.mem.Allocator, snakeHead: *Position, snakeDirection: Direction, tail: *PositionQueue, tailLength: *i32, isGameOngoing: *bool, apple: *Position) !void {
    const newPos = torwards(snakeHead.*, snakeDirection);

    const inBounds = newPos.x >= 0 and newPos.x < gameTilesX and newPos.y >= 0 and newPos.y < gameTilesY;

    var onTail = false;
    var node: ?*PositionQueue.Node = tail.first;
    while (node != null) {
        if (node.?.value.x == newPos.x and node.?.value.y == newPos.y) {
            onTail = true;
        }
        node = node.?.next;
    }

    if (inBounds and !onTail) {
        try tail.enqueue(snakeHead.*);
        if (tail.size > tailLength.*) {
            _ = tail.dequeue();
        }
        snakeHead.* = newPos;
    } else {
        isGameOngoing.* = false;
    }

    if (apple.x == snakeHead.x and apple.y == snakeHead.y) {
        tailLength.* += 1;
        try moveApple(allocator, snakeHead.*, tail, apple);
    }
}

fn moveApple(allocator: std.mem.Allocator, snakeHead: Position, tail: *PositionQueue, apple: *Position) !void {
    var validSpots = std.ArrayList(Position).init(allocator);
    defer validSpots.deinit();
    for (0..gameTilesX) |x| {
        yLoop: for (0..gameTilesY) |y| {
            if (tail.first != null) {
                var ptr: ?*PositionQueue.Node = tail.first;
                while (ptr != null) {
                    if (ptr.?.*.value.x == x and ptr.?.*.value.y == y) {
                        continue :yLoop;
                    }
                    ptr = ptr.?.*.next;
                }
            }

            if (x == snakeHead.x and y == snakeHead.y) {
                continue :yLoop;
            }

            var pos: *Position = try validSpots.addOne();
            pos.x = @intCast(x);
            pos.y = @intCast(y);
        }
    }

    var i: usize = undefined;
    try std.posix.getrandom(std.mem.asBytes(&i));
    i = i % validSpots.items.len;
    apple.* = validSpots.items[i];
}

fn takeUserInput(direction: *Direction, oldDirection: Direction) void {
    const Key = raylib.KeyboardKey;
    if (raylib.isKeyPressed(Key.w) or raylib.isKeyPressed(Key.up)) {
        if (oldDirection != Direction.south) {
            direction.* = Direction.north;
        }
    } else if (raylib.isKeyPressed(Key.a) or raylib.isKeyPressed(Key.left)) {
        if (oldDirection != Direction.east) {
            direction.* = Direction.west;
        }
    } else if (raylib.isKeyPressed(Key.s) or raylib.isKeyPressed(Key.down)) {
        if (oldDirection != Direction.north) {
            direction.* = Direction.south;
        }
    } else if (raylib.isKeyPressed(Key.d) or raylib.isKeyPressed(Key.right)) {
        if (oldDirection != Direction.west) {
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
