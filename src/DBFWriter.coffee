fs = require 'fs'
util = require 'util'
path = require 'path'
{Buffer} = require 'buffer'
{Iconv}  = require 'iconv'
JSZip = require "jszip"
FileKit = require "./FileKit"

execSync = require 'exec-sync'

FIELDSIZE = 
    C: 255
    D: 8
    N: 21
    L: 1

lFill = (str, len, char)->
    while str.length < len
        str = char + str
    str

rFill = (str, len, char)->
    while str.length < len
        str = str + char
    str


class DBFWriter
    ###
    header: {
        name: 'name', 
        type: 'D'
    }
    ###
    constructor: (header, @doc, @fileName, @dirName="./", options) ->
        if !(util.isArray header)
            throw new Error "first paramter must be a Array object to indicate header!"
        if !(util.isArray @doc)
            throw new Error "second paramter must be a Array object hold all data to write!"
        # if typeof @dirName != "string"
            # throw new Error "you must provide a String object as third paramter to indicate which dir to store!"
        if typeof @fileName != "string"
            throw new Error "you must provide a String object as fourth paramter to indicate the file name!"
        @_initOptions options
        @header = []
        @_initHeader header
        if !(fs.existsSync @dirName)
            fs.mkdirSync @dirName
        @pathName = path.join @dirName, @fileName
        @iconv = new Iconv 'UTF-8', @options.encoding+'//IGNORE'

    write: ()->
        if fs.existsSync(FileKit.makeSuffix @pathName, "dbf") and @options.coverIfFileExist==false
            throw new Error "the dbf file aready exist!"
        fs.writeFileSync (FileKit.makeSuffix @pathName, "dbf"), @_generate()

    writeZip: ()->
        if fs.existsSync(FileKit.makeSuffix @pathName, "zip") and @options.coverIfFileExist==false
            throw new Error "the file aready exist!"
        wsBuffer = @_generate()
        zip = new JSZip()
        zip.file (FileKit.makeSuffix @fileName, "dbf"), wsBuffer, 
            compression: "DEFLATE"
            base64: false
        fs.writeFileSync((FileKit.makeSuffix @pathName, "zip"), zip.generate
            type: "nodebuffer"
        )

    writeZipByLocal: ()->
        if fs.existsSync(FileKit.makeSuffix @pathName, "zip") and @options.coverIfFileExist==false
            throw new Error "the zip file aready exist!"
        @write()
        cmd = "zip -m #{FileKit.makeSuffix @pathName, "zip"} #{FileKit.makeSuffix @pathName, "dbf"}"
        result = execSync cmd, true
        throw new Error result.stderr if result.stderr
        throw new Error result.stdout unless fs.existsSync(FileKit.makeSuffix @pathName, "zip")

    _generate: ()->
        wsBuffer = new Buffer 32 + 32*@header.length + 1 + @header.totalFieldsLength*@doc.length + 1
        @_writeBufferHead wsBuffer
        @_writeBufferBody wsBuffer
        return wsBuffer

    _initOptions: (options)->
        @options = {}
        if options
            if options.encoding && typeof options.encoding == 'string'
                @options.encoding = options.encoding
            else
                @options.encoding = 'gb2312'
            if options.coverIfFileExist == false
                @options.coverIfFileExist = options.coverIfFileExist
            else
                @options.coverIfFileExist = true
        else
            @options.encoding = 'gb2312'
            @options.coverIfFileExist = true

    _initHeader: (header)->
        totalFieldsLength = 1
        for head in header
            if FIELDSIZE[head.type]
                head.size = FIELDSIZE[head.type]
                head.precision = 0 unless head.precision
                totalFieldsLength += head.size
            else
                throw new Error "the type \"#{head.type}\" in header doesn't support!"
            @header.push head
        @header.totalFieldsLength = totalFieldsLength

    _writeBufferHead: (wsBuffer)->
        now = new Date()
        wsBuffer.writeUInt8 3, 0,
        wsBuffer.writeUInt8 now.getFullYear() - 1900, 1
        wsBuffer.writeUInt8 now.getMonth() + 1, 2
        wsBuffer.writeUInt8 now.getDate(), 3 
        wsBuffer.writeUInt32LE @doc.length, 4 
        wsBuffer.writeUInt16LE 32 + 32*@header.length + 1, 8 
        wsBuffer.writeUInt16LE @header.totalFieldsLength, 10
        wsBuffer.fill 0, 12, 32
        offset = 32
        for head in @header
            buf = @iconv.convert head.name
            # console.log buf+":"+buf.length
            k = 0
            while k<buf.length&&k<10
                wsBuffer.writeUInt8 buf.readUInt8(k++), offset++
            while k<11
                wsBuffer.writeUInt8 0, offset++
                k++
            wsBuffer.writeUInt8 head.type.charCodeAt(0), offset++
            wsBuffer.writeUInt32LE 0, offset
            offset += 4
            wsBuffer.writeUInt8 head.size, offset++
            wsBuffer.writeUInt8 head.precision, offset++
            wsBuffer.fill 0, offset, offset+14
            offset += 14
        wsBuffer.writeUInt8 13, offset++
        return wsBuffer

    _writeBufferBody: (wsBuffer)->
        offset = 32 + 32*@header.length + 1
        for coll in @doc
            wsBuffer.writeUInt8 32, offset++ # delete flag: 32 means deleted
            for head in @header
                val = coll[head.name]
                switch head.type
                    when 'C'
                        offset = @_writeBufferString val, head, wsBuffer, offset
                    when 'D'
                        offset = @_writeBufferDate val, head, wsBuffer, offset
                    when 'N'
                        offset = @_writeBufferNumber val, head, wsBuffer, offset
                    when 'L'
                        offset = @_writeBufferLogic val, head, wsBuffer, offset
        wsBuffer.writeUInt8 26, offset#26 (1Ah) EOF marker
    _writeBufferString: (val, head, wsBuffer, offset)->
        val = "" unless val
        if val instanceof Date
            val = "#{val.getFullYear()}-#{lFill (val.getMonth()+1).toString(), 2, '0'}-#{lFill val.getDate().toString(), 2, '0'} #{(lFill val.getHours().toString() , 2, '0')}:#{(lFill val.getMinutes().toString() , 2, '0')}:#{(lFill val.getSeconds().toString() , 2, '0')}"
            buf = new Buffer val
        else 
            buf = @iconv.convert val.toString()
        @_writeBufferChar buf, head, wsBuffer, offset
    _writeBufferDate: (val, head, wsBuffer, offset)->
        val = "" unless val
        if val instanceof Date
            val = "#{val.getFullYear()}#{lFill (val.getMonth()+1).toString(), 2, '0'}#{lFill val.getDate().toString(), 2, '0'}"
        buf = new Buffer val.toString()
        @_writeBufferChar buf, head, wsBuffer, offset
    _writeBufferNumber: (val, head, wsBuffer, offset)->
        val = "" if val != 0 && !val
        if typeof val == 'number'
            val = val.toFixed head.precision
        else
            val = (parseFloat val).toFixed head.precision
        if isNaN val
            val = ""
        @_writeBufferDecimal val, head, wsBuffer, offset
    _writeBufferLogic: (val, head, wsBuffer, offset)->
        val = "?" if val != false && !val
        val = val.toString().toUpperCase().charCodeAt 0
        wsBuffer.writeUInt8 val, offset++
        offset++
    _writeBufferChar: (buf, head, wsBuffer, offset)->
        k = 0
        size = head.size
        length = buf.length
        while k<length && k<size
            wsBuffer.writeUInt8 buf.readUInt8(k++), offset++
        if k<size
            wsBuffer.fill ' ', offset, offset+size-k
        offset = offset+size-k
    _writeBufferDecimal: (val, head, wsBuffer, offset)->
        val = val.toString()
        k = 0
        size = head.size
        val = lFill val, size, ' '
        val = val.substring 0, size
        buf = new Buffer val
        while k<size
            wsBuffer.writeUInt8 buf.readUInt8(k++), offset++
        offset

module.exports = DBFWriter