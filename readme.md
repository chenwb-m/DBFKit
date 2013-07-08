
## Example

### DBFWriter
    dbfkit = require "dbfkit"
    DBFWriter = dbfkit.DBFWriter

    header = [
    {
      name: 'name',
      type: 'C'
    }, {
      name: 'gender',
      type: 'L'
    }, {
      name: 'birthday',
      type: 'D'
    }, {
      name: 'stature',
      type: 'N',
      precision: '2'
    }, {
      name: 'registDate',
      type: 'C'
    }
    ];

    doc = [
    {
      name: 'charmi',
      gender: true,
      birthday: new Date(),
      stature: 0,
      registDate: new Date()
    }, {
      name: '张三',
      gender: false,
      birthday: new Date(1935, 1, 2),
      stature: 1.87,
      registDate: new Date()
    }
    ];

    pathName = './dbfout';
    fileName = 'people.dbf';
    dbfWriter = new DBFWriter(header, doc, fileName, pathName, {
    encoding: 'gb2312',
    coverIfFileExist: true
    });
    dbfWriter.write();
    console.log("finish");

### DBFParser
    dbfkit = require "dbfkit"
    DBFParser = dbfkit.DBFParser
    
    pathName = './dbfout';
    fileName = 'people.dbf';
    dbfParser = new DBFParser(pathName + "/" + fileName, "GBK");

    dbfParser.on('head', function(head) {
    return console.log(head);
    });
    dbfParser.on('record', function(record) {
    return console.log(record);
    });
    dbfParser.on('end', function() {
    return console.log('finish');
    });

    dbfParser.parse();