const std = @import("std");
const raylib = @import("raylib");
const Color = raylib.Color;
const types = @import("types.zig");
const Position = types.Position;
const PositionQueue = types.PositionQueue;
const Direction = types.Direction;

pub const windowWidth: i32 = 600;
pub const windowHeight: i32 = 600;
pub const windowTitle: [:0]const u8 = "Snake";

pub const gameTilesX: i16 = 20;
pub const gameTilesY: i16 = 20;
pub const gameSpacingX: i16 = 20;
pub const gameSpacingY: i16 = 20;

pub const groundColorA: Color = .{
    .r = 100,
    .g = 100,
    .b = 100,
    .a = 255,
};

pub const groundColorB: Color = .{
    .r = 120,
    .g = 120,
    .b = 120,
    .a = 255,
};

pub const snakeHeadColor: Color = .{
    .r = 50,
    .g = 50,
    .b = 180,
    .a = 255,
};

pub const snakeTailColor: Color = .{
    .r = 50,
    .g = 80,
    .b = 140,
    .a = 255,
};

pub const appleColor: Color = .{
    .r = 255,
    .g = 50,
    .b = 50,
    .a = 255,
};

pub const deathText = "Game over!";
pub const deathTextSize = 60;
pub const deathRestartText = "Press space to restart";
pub const deathRestartSize = 30;
pub const deathRestartOffset = 100;
pub const deathTextColor: Color = .{
    .r = 240,
    .g = 60,
    .b = 60,
    .a = 255,
};

pub const gameTileSizeX = (windowWidth - (gameSpacingX * 2)) / gameTilesX;
pub const gameTileSizeY = (windowWidth - (gameSpacingY * 2)) / gameTilesY;

pub fn render(snakeHead: Position, tail: *PositionQueue, apple: Position, isGameOngoing: bool) void {
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
    }
}

pub fn resetGame(allocator: std.mem.Allocator, snakeHead: *Position, snakeDirection: *Direction, tail: *PositionQueue, tailLength: *i32, isGameOngoing: *bool, apple: *Position, targetTickTime: *f32) !void {
    snakeHead.* = .{ .x = gameTilesX / 2, .y = gameTilesY / 2 };
    snakeDirection.* = Direction.north;
    tail.deinit();
    tail.* = PositionQueue.init(allocator);
    tailLength.* = 0;
    try moveApple(allocator, snakeHead.*, tail, apple);
    targetTickTime.* = 0.2;
    isGameOngoing.* = true;
}

pub fn tickGame(allocator: std.mem.Allocator, snakeHead: *Position, snakeDirection: Direction, tail: *PositionQueue, tailLength: *i32, isGameOngoing: *bool, apple: *Position, targetTickTime: *f32) !void {
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
        targetTickTime.* -= targetTickTime.* / 20.0;
        try moveApple(allocator, snakeHead.*, tail, apple);
    }
}

pub fn moveApple(allocator: std.mem.Allocator, snakeHead: Position, tail: *PositionQueue, apple: *Position) !void {
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

pub fn validSnakePos(position: Position, tail: *PositionQueue) bool {
    if (position.x < 0 or position.x >= gameTilesX or position.y < 0 or position.y >= gameTilesY) {
        return false;
    }

    if (tailCollides(position, tail)) {
        return false;
    }

    return true;
}

pub fn tailCollides(position: Position, tail: *PositionQueue) bool {
    var n: ?*PositionQueue.Node = tail.first;
    while (n) |node| {
        if (node.value.x == position.x and node.value.y == position.y) {
            return true;
        }
        n = node.next;
    }
    return false;
}

test "torwards" {
    const testing = std.testing;

    const pos: Position = .{ .x = 10, .y = 20 };

    try testing.expectEqual(Position{ .x = 10, .y = 19 }, torwards(pos, Direction.north));
    try testing.expectEqual(Position{ .x = 10, .y = 21 }, torwards(pos, Direction.south));
    try testing.expectEqual(Position{ .x = 11, .y = 20 }, torwards(pos, Direction.east));
    try testing.expectEqual(Position{ .x = 9, .y = 20 }, torwards(pos, Direction.west));
}
