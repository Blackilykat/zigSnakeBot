const std = @import("std");
const ArrayList = std.ArrayList;

const queue = @import("queue.zig");

const types = @import("types.zig");
const Direction = types.Direction;
const Position = types.Position;
const PositionQueue = types.PositionQueue;

const game = @import("game.zig");

const hiddenLayerAmount = 20;
const hiddenLayerSize = 50;

const Link = struct {
    neuron: *Neuron,
    weight: f64 = 1,
};

const Neuron = struct {
    weight: f64 = 1,
    previousNodes: ?ArrayList(Link),
};

const Network = struct {
    var arena: ?std.heap.ArenaAllocator = null;
    pub var inputNodes: ArrayList(Neuron) = undefined;
    pub var hiddenLayers: ArrayList(ArrayList(Neuron)) = undefined;
    pub var outputNodes: ArrayList(Neuron) = undefined;

    pub fn init(allocator: std.mem.Allocator) !void {
        arena = std.heap.ArenaAllocator.init(allocator);

        inputNodes = ArrayList(Neuron).init(arena.?);

        for (0..game.gameTilesY * game.gameTilesX) |_| {
            inputNodes.append(.{ .previousNodes = null });
        }

        hiddenLayers = ArrayList(ArrayList(Neuron)).init(arena.?);
        for (0..hiddenLayerAmount) |layer| {
            hiddenLayers.append(ArrayList(Neuron).init(arena.?));
            for (0..hiddenLayerSize) |_| {
                var neuron: Neuron = .{ .previousNodes = ArrayList(Neuron).init(arena.?) };
                if (layer != 0) {
                    const previousNeurons = hiddenLayers.items[layer].previousNodes.?;
                    for (previousNeurons.items) |*item| {
                        neuron.previousNodes.?.append(.{ .neuron = item });
                    }
                } else {
                    for (inputNodes.items) |*item| {
                        neuron.previousNodes.?.append(.{ .neuron = item });
                    }
                }
                hiddenLayers.getLast().append(neuron);
            }
        }

        outputNodes = ArrayList(Neuron).init(arena.?);

        // 4 directions
        for (0..4) |_| {
            var neuron: Neuron = .{ .previousNodes = ArrayList(Neuron).init(arena.?) };
            for (hiddenLayers.getLast().items) |*item| {
                neuron.previousNodes.?.append(.{ .neuron = item });
            }
            outputNodes.append(neuron);
        }
    }

    pub fn deinit() void {
        if (arena) |a| {
            a.deinit();
        }
    }
};

pub fn takeBotInput(network: *Network, direction: *Direction, pos: Position, tail: *PositionQueue, apple: Position) !void {
    var input: [game.gameTilesY][game.gameTilesX]f64 = undefined;
    for (0..game.gameTilesY) |y| {
        for (0..game.gameTilesX) |x| {
            input[y][x] = 0.0;
        }
    }

    var tailNode: ?*PositionQueue.Node = tail.first;
    while (tailNode) |node| {
        input[node.value.y][node.value.x] = 0.5;
        tailNode = node.next;
    }

    input[pos.y][pos.x] = 0.6;
    input[apple.y][apple.x] = 1.0;

    for (0..input.len) |y| {
        for (0..input[y].len) |x| {
            network.inputNodes.items[y * input[y].len + x] = input[y][x];
        }
    }

    for (network.hiddenLayers.items) |layer| {
        for (layer.items) |node| {
            node.weight = 0;
            for (node.previousNodes.?.items) |prev| {
                node.weight += prev.neuron.weight * prev.weight;
            }
            node.weight = relu(node.weight);
        }
    }

    var i: u8 = 0;
    var directionPicked: u8 = 0;
    for (network.outputNodes.items) |node| {
        node.weight = 0;
        for (node.previousNodes.?.items) |prev| {
            node.weight += prev.neuron.weight * prev.weight;
        }
        node.weight = relu(node.weight);

        if (node.weight > network.outputNodes.items[directionPicked]) {
            directionPicked = i;
        }

        i += 1;
    }

    switch (directionPicked) {
        0 => {
            direction.* = Direction.north;
        },
        1 => {
            direction.* = Direction.east;
        },
        2 => {
            direction.* = Direction.south;
        },
        3 => {
            direction.* = Direction.west;
        },
    }
}

fn relu(n: f64) f64 {
    if (n < 0) return 0;
    return n;
}
