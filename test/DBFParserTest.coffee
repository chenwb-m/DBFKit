DBFParser = require "../src/DBFParser"
fs = require 'fs'

pathName = './dbfout'
fileName = 'HQMS_DB_2013-12-06.dbf'

dbfParser = new DBFParser pathName+"/"+fileName, "GBK"

dbfParser.on 'head', (head)->
    fs.writeFileSync pathName+"/"+fileName+"_head.txt", (JSON.stringify head, undefined, 2)
    console.log head

dbfParser.on 'record', (record)->
    fs.writeFileSync pathName+"/"+fileName+"_record.txt", (JSON.stringify record, undefined, 2)
    console.log head

dbfParser.on 'end', ()->
    console.log 'finish'

dbfParser.parse()