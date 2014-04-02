DBFParser = require "../src/DBFParser"
fs = require 'fs'

pathName = './dbfout'
fileName = 'people.dbf'

dbfParser = new DBFParser pathName+"/"+fileName, "GBK"

dbfParser.on 'head', (head)->
    fs.writeFileSync pathName+"/"+fileName+"_head.txt", (JSON.stringify head, undefined, 2)
    console.log head

dbfParser.on 'record', (record)->
    fs.writeFileSync pathName+"/"+fileName+"_record.txt", (JSON.stringify record, undefined, 2)
    console.log record

dbfParser.on 'end', ()->
    console.log 'finish'

dbfParser.parse()