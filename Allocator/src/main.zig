const std = @import("std");
const mem = std.mem;
const Allocator = std.mem.Allocator;

pub const LinearAllocator = struct {
    underlying: Allocator,
    buffer: []u8,
    index: usize,

    pub fn init(underlying: Allocator, size: usize) !LinearAllocator {
        return LinearAllocator{
            .underlying = underlying,
            .buffer = try underlying.alloc(u8, size),
            .index = 0,
        };
    }

    pub fn deinit(self: LinearAllocator) void {
        self.underlying.free(self.buffer); }
    pub fn allocator(self: *LinearAllocator) Allocator {
        return Allocator.init(self, alloc, resize, free); }

    fn alloc(self: *LinearAllocator, size: usize, ptr_align: u29, len_align: u29, ret_addr: usize)
    error{OutOfMemory}![]u8 {
        _ = len_align; _ = ret_addr;
        const aligned_ptr = mem.alignForward(@ptrToInt(self.buffer.ptr) + self.index, ptr_align);
        const aligned_idx = aligned_ptr - @ptrToInt(self.buffer.ptr);
        const end_index = aligned_idx + size;
        if(end_index >= self.buffer.len) return error.OutOfMemory;
        const allocation = self.buffer[aligned_idx..end_index];
        self.index = end_index;
        return allocation;
    }

    fn free(self *LinearAllocator, buf: []u8, buf_align: u29, ret_addr: usize)
    void {
        _ = self;
        _ = buf_align;
        _ = ret_addr;
        _ = buf;
    }
};
