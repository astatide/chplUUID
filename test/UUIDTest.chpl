config const testParam: bool = true;

use UUID;

if testParam {

  var uuid = new owned UUID.UUIDGenerator();
  var id = uuid.UUID4(); // id is a v4 UUID
  writeln('ID %s successfully generated!'.format(id));

}
