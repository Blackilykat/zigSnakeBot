const std = @import("std");
const queue = @import("queue.zig");

const types = @import("types.zig");
const Direction = types.Direction;
const Position = types.Position;
const PositionQueue = types.PositionQueue;

const game = @import("game.zig");

const Node = struct {
    pos: Position,
    parent: ?*@This(),
};

const NodeQueue = queue.Queue(*Node);

pub fn takeBotInput(allocator: std.mem.Allocator, direction: *Direction, pos: Position, tail: *PositionQueue, apple: Position) !void {
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

    var visited: [game.gameTilesY][game.gameTilesX]bool = undefined;
    for (&visited) |*row| {
        for (row) |*value| {
            value.* = false;
        }
    }

    var foundPath = false;

    while (q.size > 0 and !foundPath) {
        const visiting: *Node = q.dequeue().?;

        if (!game.validSnakePos(visiting.pos, tail)) {
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
        if (game.validSnakePos(.{ .x = pos.x, .y = pos.y - 1 }, tail)) direction.* = Direction.north;
        if (game.validSnakePos(.{ .x = pos.x + 1, .y = pos.y }, tail)) direction.* = Direction.east;
        if (game.validSnakePos(.{ .x = pos.x, .y = pos.y + 1 }, tail)) direction.* = Direction.south;
        if (game.validSnakePos(.{ .x = pos.x - 1, .y = pos.y }, tail)) direction.* = Direction.west;
    }
}
