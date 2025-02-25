const std = @import("std");
const raylib = @import("raylib");
const Color = raylib.Color;
const queue = @import("queue.zig");
const game = @import("game.zig");
const types = @import("types.zig");
const Position = types.Position;
const PositionQueue = types.PositionQueue;
const Direction = types.Direction;
const bot = @import("bot.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    raylib.initWindow(game.windowWidth, game.windowHeight, game.windowTitle);
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

    try game.resetGame(allocator, &snakeHead, &snakeDirection, &tail, &tailLength, &isGameOngoing, &apple, &targetTickTime);

    while (!raylib.windowShouldClose()) {
        raylib.beginDrawing();

        currentTickTime += raylib.getFrameTime();

        raylib.clearBackground(Color.black);

        game.render(snakeHead, &tail, apple, isGameOngoing);

        if (!isGameOngoing) {
            if (raylib.isKeyPressed(raylib.KeyboardKey.space)) {
                try game.resetGame(allocator, &snakeHead, &snakeDirection, &tail, &tailLength, &isGameOngoing, &apple, &targetTickTime);
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
                    try bot.takeBotInput(allocator, &snakeDirection, snakeHead, &tail, apple);
                }
                try game.tickGame(allocator, &snakeHead, snakeDirection, &tail, &tailLength, &isGameOngoing, &apple, &targetTickTime);
                oldSnakeDirection = snakeDirection;
            }
        }

        raylib.endDrawing();
    }
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

comptime {
    _ = @import("queue.zig");
}
