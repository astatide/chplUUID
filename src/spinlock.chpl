use SysError;

class TooManyLocksError : Error {
  proc init() { }
}

class SpinLock {
  var l: atomic bool;
  var n: atomic int;
  var t: string;
  var writeLock: atomic int;
  var readHandles: atomic int;

  inline proc lock() throws {
    while l.testAndSet(memory_order_acquire) do chpl_task_yield();
    this.n.add(1);
    if this.n.read() != 1 {
      throw new owned TooManyLocksError();
    }
  }

  inline proc unlock() throws {
    this.n.sub(1);
    if this.n.read() != 0 {
      throw new owned TooManyLocksError();
    }
    l.clear(memory_order_release);
  }

  inline proc rl() {
    // This checks to see whether the write lock is active, and if not,
    // allows reads.
    while this.writeLock.read() >= 1 do chpl_task_yield();
    this.readHandles.add(1);
  }

  inline proc url() {
    this.readHandles.sub(1);
  }

  inline proc wl() {
    // While we are actively reading, we do not write.
    this.writeLock.add(1);
    while this.readHandles.read() != 0 do chpl_task_yield();
    this.lock();
  }

  inline proc uwl() {
    this.writeLock.sub(1);
    this.unlock();
  }
}
