DBFParser = require "../src/DBFParser"

pathName = './dbfout'
fileName = 'people.dbf'

dbfParser = new DBFParser pathName+"/"+fileName, "GBK"

dbfParser.on 'head', (head)->
    console.log head

dbfParser.on 'record', (record)->
    console.log record

dbfParser.on 'end', ()->
    console.log 'finish'

dbfParser.parse()