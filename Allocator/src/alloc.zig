const std = @import("std");
const os = std.os;
const mem = std.mem;
const testing = std.testing;
const builtin = @import("builtin");
const c = std.c;
const Allocator = mem.Allocator;
const debug = std.debug;
const assert = debug.assert;

pub const Arena_Allocator = struct {
  child_alloc: Allocator,
  buffer_list: std.SinglyLinkedList([]u8),
  end: usize,

  const buf_node = std.SingleLinkedList([]u8).Node;

  pub fn init(child_alloc: *Allocator) Arena_Allocator {
    return Arena_Allocator{

      .child_alloc = child_alloc,
      .buffer_list = std.SinglyLinkedList([]u8).init(),
      .end = 0,
    };
  }

  pub fn destroy(self: *Arena_Allocator) void {
    var it = self.buffer_list.first;
    while(it) |node| {
      const next_it = node.next;
      self.child_alloc.free(node.data);
      it = next_it;
    }
  }

  fn create_node(self: *Arena_Allocator, prev: usize, min: usize) !*buf_node {
    const true_min = min + @sizeOf(buf_node);
    var len = prev;
    while(true) {
      len += len / 2;
      len += mem.page_size - @rem(len, mem.page_size);
      if(len >= true_min) break;
    }
    const buf = try self.child_allocator.alignedAlloc(u8, @alignOf(buf_node), len);
    const buf_slice = std.mem.bytesToSlice(buf_node, buf[0..@sizeOf(buf_node)]);
    const node = &buf_slice[0];
    node.* = buf_node{
      .data = buf,
      .next = null,
    };
    self.buffer_list.prepend(buf);
    self.end = 0;
    return buf;
  }

  fn alloc(malloc: *Allocator, n: usize, alignment: u29) ![]u8 {
    const self = @fieldParentPtr(Arena_Allocator, "allocator", malloc);
    var cur = if(self.buffer_list.first) |first| first else try self.create_node(0, n + alignment);
    while(true) {
      const buf = cur.data[@sizeOf(buf_node)..];
      const addr = @ptrToInt(buf.ptr) + self.end;
      const mod_addr = mem.alignForward(addr, alignment);
      const mod_index = self.end + (mod_addr - addr);
      const new_end = mod_index + n;
      if(new_end > buf.len) {
        cur = try self.create_node(buf.len, n + alignment);
        continue;
      }
      const result = buf[mod_index..new_end];
      self.end = new_end;
      return result;
    }
  }
  
  fn realloc(malloc: *Allocator, omem: []u8, oalign: u29, size: usize, nalign: u29) []u8 {
    _ = oalign;
    if(size <= omem.len and nalign <= size) {
      return error.OutOfMemory;
    } else {
      const result = try alloc(malloc, size, nalign);
      @memcpy(result.ptr, omem.ptr, std.math.min(omem.len, result.len));
      return result;
    }
  }

  fn shrink(malloc: *Allocator, omem: []u8, oalign: u29, size: usize, nalign: u29) []u8 {
    _ = malloc;
    _ = nalign;
    _ = oalign;
    return omem[0..size];
  }
};

test "Arena_Allocator" {
  var aa = Arena_Allocator.init(std.heap.page_allocator);
  defer aa.destroy();

  try testAllocator(&aa.allocator);
}

fn testAllocator(allocator: *mem.Allocator) !void {
    var slice = try allocator.alloc(*i32, 100);
    testing.expect(slice.len == 100);
    for (slice) |*item, i| {
        item.* = try allocator.create(i32);
        item.*.* = @intCast(i32, i);
    }

    slice = try allocator.realloc(slice, 20000);
    testing.expect(slice.len == 20000);

    for (slice[0..100]) |item, i| {
        testing.expect(item.* == @intCast(i32, i));
        allocator.destroy(item);
    }

    slice = allocator.shrink(slice, 50);
    testing.expect(slice.len == 50);
    slice = allocator.shrink(slice, 25);
    testing.expect(slice.len == 25);
    slice = allocator.shrink(slice, 0);
    testing.expect(slice.len == 0);
    slice = try allocator.realloc(slice, 10);
    testing.expect(slice.len == 10);

    allocator.free(slice);
}
