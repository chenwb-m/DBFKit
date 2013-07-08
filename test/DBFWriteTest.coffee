DBFWriter = require "../src/DBFWriter"

header = [
        name: 'name'
        type: 'C'
    ,
        name: 'gender'
        type: 'L'
    ,
        name: 'birthday'
        type: 'D'
    ,
        name: 'stature'
        type: 'N'
        precision: '2'
    ,
        name: 'registDate'
        type: 'C'
]
doc = [
        name: 'charmi'
        gender: true
        birthday: new Date()
        stature: 0
        registDate: new Date()
    ,
        name: '张三'
        gender: false
        birthday: new Date(1935, 1, 2)
        stature: 1.87
        registDate: new Date()
    ,
        kit:32
]
pathName = './dbfout'
fileName = 'people'

dbfWriter = new DBFWriter header, doc, fileName, pathName, 
    encoding: 'gb2312'
    coverIfFileExist: false
dbfWriter.writeZip()


console.log "finish"
#console.log 21.toFixed(2).toString().charCodeAt(0)