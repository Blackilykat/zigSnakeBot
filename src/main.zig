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

    var targetTickTime: f32 = 0;

    var tailLength: i32 = 0;

    var tail = PositionQueue.init(allocator);

    var snakeHead: Position = .{};
    var snakeDirection: Direction = Direction.north;
    var oldSnakeDirection: Direction = Direction.north;

    var currentTickTime: f32 = 0.0;

    var isGameOngoing = false;

    var apple: Position = .{};

    var isBotControlling = true;

    try resetGame(allocator, &snakeHead, &snakeDirection, &tail, &tailLength, &isGameOngoing, &apple, &targetTickTime);

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
                try resetGame(allocator, &snakeHead, &snakeDirection, &tail, &tailLength, &isGameOngoing, &apple, &targetTickTime);
            }
        }

        if (raylib.isKeyPressed(raylib.KeyboardKey.enter)) {
            isBotControlling = !isBotControlling;
        }

        if (!isBotControlling) {
            takeUserInput(&snakeDirection, oldSnakeDirection);
        }

        if (currentTickTime > targetTickTime) {
            currentTickTime -= targetTickTime;
            if (isGameOngoing) {
                if (isBotControlling) {
                    try takeBotInput(allocator, &snakeDirection, snakeHead, &tail, apple);
                }
                try tickGame(allocator, &snakeHead, snakeDirection, &tail, &tailLength, &isGameOngoing, &apple, &targetTickTime);
                oldSnakeDirection = snakeDirection;
            }
        }

        raylib.endDrawing();
    }
}

fn resetGame(allocator: std.mem.Allocator, snakeHead: *Position, snakeDirection: *Direction, tail: *PositionQueue, tailLength: *i32, isGameOngoing: *bool, apple: *Position, targetTickTime: *f32) !void {
    snakeHead.* = .{ .x = gameTilesX / 2, .y = gameTilesY / 2 };
    snakeDirection.* = Direction.north;
    tail.deinit();
    tail.* = PositionQueue.init(allocator);
    tailLength.* = 0;
    try moveApple(allocator, snakeHead.*, tail, apple);
    targetTickTime.* = 0.2;
    isGameOngoing.* = true;
}

fn tickGame(allocator: std.mem.Allocator, snakeHead: *Position, snakeDirection: Direction, tail: *PositionQueue, tailLength: *i32, isGameOngoing: *bool, apple: *Position, targetTickTime: *f32) !void {
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

fn takeBotInput(allocator: std.mem.Allocator, direction: *Direction, pos: Position, tail: *PositionQueue, apple: Position) !void {
    const Node = struct {
        pos: Position,
        parent: ?*@This(),
    };
    const NodeQueue = queue.Queue(*Node);

    var arena = std.heap.ArenaAllocator.init(allocator);
    var arenaAlloc = arena.allocator();
    defer arena.deinit();

    var q: NodeQueue = NodeQueue.init(allocator);
    defer q.deinit();

    const firstNode: *Node = try arenaAlloc.create(Node);
    firstNode.pos = pos;
    firstNode.parent = null;
    try q.enqueue(firstNode);

    var firstMovement: Position = undefined;

    var visited: [gameTilesY][gameTilesX]bool = undefined;
    for (&visited) |*row| {
        for (row) |*value| {
            value.* = false;
        }
    }

    var foundPath = false;

    while (q.size > 0 and !foundPath) {
        const visiting: *Node = q.dequeue().?;

        if (!validSnakePos(visiting.pos, tail)) {
            continue;
        }

        if (visited[@intCast(visiting.pos.x)][@intCast(visiting.pos.y)]) {
            continue;
        }

        if (visiting.pos.x == apple.x and visiting.pos.y == apple.y) {
            foundPath = true;

            var n: ?*Node = visiting;
            while (n != null and n.?.parent != null and n.?.parent.?.parent != null) {
                n = n.?.parent;
            }

            firstMovement = n.?.pos;

            break;
        }

        visited[@intCast(visiting.pos.x)][@intCast(visiting.pos.y)] = true;

        const northNode: *Node = try arenaAlloc.create(Node);
        northNode.pos = .{ .x = visiting.pos.x, .y = visiting.pos.y - 1 };
        northNode.parent = visiting;
        try q.enqueue(northNode);

        const eastNode: *Node = try arenaAlloc.create(Node);
        eastNode.pos = .{ .x = visiting.pos.x + 1, .y = visiting.pos.y };
        eastNode.parent = visiting;
        try q.enqueue(eastNode);

        const southNode: *Node = try arenaAlloc.create(Node);
        southNode.pos = .{ .x = visiting.pos.x, .y = visiting.pos.y + 1 };
        southNode.parent = visiting;
        try q.enqueue(southNode);

        const westNode: *Node = try arenaAlloc.create(Node);
        westNode.pos = .{ .x = visiting.pos.x - 1, .y = visiting.pos.y };
        westNode.parent = visiting;
        try q.enqueue(westNode);
    }

    try std.io.getStdOut().writer().print("Found path: {any}\n", .{foundPath});
    if (foundPath) {
        try std.io.getStdOut().writer().print("first {any}, pos {any} \n", .{ firstMovement, pos });
        if (firstMovement.y < pos.y) direction.* = Direction.north;
        if (firstMovement.x > pos.x) direction.* = Direction.east;
        if (firstMovement.y > pos.y) direction.* = Direction.south;
        if (firstMovement.x < pos.x) direction.* = Direction.west;
    } else {
        if (validSnakePos(.{ .x = pos.x, .y = pos.y - 1 }, tail)) direction.* = Direction.north;
        if (validSnakePos(.{ .x = pos.x + 1, .y = pos.y }, tail)) direction.* = Direction.east;
        if (validSnakePos(.{ .x = pos.x, .y = pos.y + 1 }, tail)) direction.* = Direction.south;
        if (validSnakePos(.{ .x = pos.x - 1, .y = pos.y }, tail)) direction.* = Direction.west;
    }
}

fn validSnakePos(position: Position, tail: *PositionQueue) bool {
    if (position.x < 0 or position.x >= gameTilesX or position.y < 0 or position.y >= gameTilesY) {
        return false;
    }

    if (tailCollides(position, tail)) {
        return false;
    }

    return true;
}

fn tailCollides(position: Position, tail: *PositionQueue) bool {
    var n: ?*PositionQueue.Node = tail.first;
    while (n) |node| {
        if (node.value.x == position.x and node.value.y == position.y) {
            return true;
        }
        n = node.next;
    }
    return false;
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
