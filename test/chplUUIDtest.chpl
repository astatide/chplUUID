config const testParam: bool = true;

use chplUUID;

if testParam {

  var UUID = new owned chplUUID.UUID();
  var id = UUID.UUID4(); // id is a v4 UUID
  writeln('ID %s successfully generated!'.format(id));

}
