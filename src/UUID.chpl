/*

  A basic module to generate v4 UUIDs.  Pulls from /dev/urandom, and is thread
  safe as it implements utilizes a lock (ensuring that only one task may pull
  from the entropy source at a time).

  .. highlight:: chapel

  ::

    use UUID;
    var uuid = new owned UUID.UUIDGenerator();
    var id = uuid.UUID4(); // id is a v4 UUID


 */
module UUID {

  // By Audrey Pratt, care of Cray

  // Load up the random module.  We need randomness!
  use Random;
  use rng;
  use spinlock;

  /*

  The module itself.  It uses the included rng module to pull 8 random bits
  from /dev/urandom directly.  This is considered a write locking operation,
  where the lock is done here and not on the rng module, so that only one task
  is allowed to pull from the entropy source at a time.  Otherwise, collisions
  are guaranteed.

  There are no user defined variables.

  */

  class UUIDGenerator {
    // This is a generic class which will be able to output a UUID4 compliant ID
    // (I mean, that's the goal, anyway; who knows if I'm doing it right).
    // We want our random stuff, so.
    var entropySource = new owned UDevRandomHandler();
    var remainder: [0..#2] string;
    // We want an array to store stuff into.
    var uuid_int_rep: [1..16] uint(8);
    var lock: shared spinlock.SpinLock;

    proc init() {
      this.lock = new shared spinlock.SpinLock();
    }

    /*

    UUID creation requires 128 bits of data, which Chapel does not inherently
    support.  Instead, we pull 8 bits at a time and store it into an associative
    array so that we can perform the necessary operations on the appropriate
    length of data.

    */

    proc pull_random_data() {
      forall i in 1..16 do {
        // Just call the appropriate function on the entropy source.
        this.uuid_int_rep[i] = abs(this.entropySource.getrandbits(8)) : uint(8);
      }
    }

    /*

    For UUID4 compliant ids, after pulling 128 bits of random data, certain
    elements have particular bitwise operations done on them.  This does that.

    */

    proc convert_to_uuid4() {
      // Not entirely certain this is correct.
      this.uuid_int_rep[7] |= 64;
      this.uuid_int_rep[9] |= 2;
    }

    /*

    Converts an integer into a hexadecimal, represented as a string.  Does this
    through the use of bitwise operations.  Assumes little endian.  This is
    the second, and final, step of the UUID creation.

    */

    // This works!  Assumes... I think little endian?  Big stuff on the left.
    // Whatever, I don't have a CS degree, it's fine.  We'll sort it later.
    proc convert_to_hex(x: uint) {
      var result: uint;
      var i: uint;
      // Can I make this global?
      //var remainder: [0..#2] string;
      const hex = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f'];
      // We have 8 bits of data; we need to split this into 4 bits and calculate
      // appropriately.
      // first, clear out the last four bits by ANDing them a number that is
      // 1 everywhere you don't want cleared, then doing a bit shift.
      this.remainder[0] = hex[(((x & 240) >> 4)+1): int];
      // now, clear out the first 4 bits.  No need to bit shift
      this.remainder[1] = hex[((x & 15)+1): int];
      return this.remainder;
    }

    /*

    The only procedure that should be called by the end user.  Quick and easy!

    */

    proc UUID4() throws {
      // Currently I can't be bothered to support custom data.  Whatever.
      // I'm sure there's a more elegant solution for this, but this is just
      // proof of concept.
      var r_uuid: string;
      this.lock.lock();
      this.pull_random_data();
      this.lock.unlock();
      this.convert_to_uuid4();
      r_uuid = '';
      for i in 1..16 do {
        for j in this.convert_to_hex(this.uuid_int_rep[i]) {
          r_uuid += j;
        }
      }
      r_uuid = r_uuid[1..8] + '-' + r_uuid[9..12] + '-' + r_uuid[13..16] +
               '-' + r_uuid[17..20] + '-' + r_uuid[21..32];
      return r_uuid;
    }
  }
}
