const queue = @import("queue.zig");

pub const Direction = enum { north, east, south, west };
pub const Position = struct { x: i32 = 0, y: i32 = 0 };
pub const PositionQueue = queue.Queue(Position);
