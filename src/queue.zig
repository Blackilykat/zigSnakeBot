const std = @import("std");

pub fn Queue(comptime T: type) type {
    return struct {
        const This = @This();
        pub const Node = struct {
            value: T,
            next: ?*Node,
        };

        first: ?*Node,
        last: ?*Node,
        gpa: std.mem.Allocator,
        size: i32 = 0,

        pub fn init(gpa: std.mem.Allocator) This {
            return This{
                .first = null,
                .last = null,
                .gpa = gpa,
            };
        }

        pub fn deinit(this: *This) void {
            var node: ?*Node = this.first;
            while (node) |existingNode| {
                node = existingNode.next;
                this.gpa.destroy(existingNode);
            }
        }

        pub fn enqueue(this: *This, value: T) !void {
            var node: *Node = try this.gpa.create(Node);
            node.value = value;
            node.next = null;
            if (this.last) |last| {
                last.*.next = node;
                this.last = node;
                this.size += 1;
            } else {
                this.first = node;
                this.last = node;
                this.size = 1;
            }
        }

        pub fn dequeue(this: *This) ?T {
            if (this.first) |first| {
                const value: T = first.value;
                this.first = first.next;
                if (this.first == null) {
                    this.last = null;
                }
                this.size -= 1;
                this.gpa.destroy(first);
                return value;
            }
            return null;
        }
    };
}

test "queueDequeue" {
    const IntQueue = Queue(i32);
    var queue: IntQueue = IntQueue.init(std.testing.allocator);

    try queue.enqueue(12);
    try queue.enqueue(42);
    try queue.enqueue(42);

    try std.testing.expectEqual(12, queue.dequeue());
    try std.testing.expectEqual(42, queue.dequeue());
    try std.testing.expectEqual(42, queue.dequeue());
    try std.testing.expectEqual(null, queue.dequeue());
}

test "queueDeinit" {
    var queue = Queue(i32).init(std.testing.allocator);

    try queue.enqueue(451);
    try queue.enqueue(111);
    try queue.enqueue(181);
    try queue.enqueue(811);
    try queue.enqueue(845);
    try queue.enqueue(999);
    try queue.enqueue(732);
    try queue.enqueue(342);
    try queue.enqueue(777);

    queue.deinit();
}
