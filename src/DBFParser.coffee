{EventEmitter} = require 'events'
fs = require 'fs'
{Iconv}  = require 'iconv'

class DBFParser extends EventEmitter
    constructor: (@fileName, @encoding='GBK') ->
        @iconv = new Iconv @encoding, 'UTF-8//IGNORE'
        # yyyy-MM-dd HH:mm:ss 
        @timeReg1 = /^(?:(?!0000)[0-9]{4}-(?:(?:0[1-9]|1[0-2])-(?:0[1-9]|1[0-9]|2[0-8])|(?:0[13-9]|1[0-2])-(?:29|30)|(?:0[13578]|1[02])-31)|(?:[0-9]{2}(?:0[48]|[2468][048]|[13579][26])|(?:0[48]|[2468][048]|[13579][26])00)-02-29)\s+([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$/
        # yyyy-MM-dd-HH
        # @timeReg2 = /^(?:(?!0000)[0-9]{4}-(?:(?:0[1-9]|1[0-2])-(?:0[1-9]|1[0-9]|2[0-8])|(?:0[13-9]|1[0-2])-(?:29|30)|(?:0[13578]|1[02])-31)|(?:[0-9]{2}(?:0[48]|[2468][048]|[13579][26])|(?:0[48]|[2468][048]|[13579][26])00)-02-29)-([01][0-9]|2[0-3])/

    parse: ->
        fs.readFile @fileName, (err, buffer)=>
            throw err if err
            @emit 'start'
            @_parseHead buffer
            @_parseRecords buffer
            @emit 'end'

    _parseHead: (buffer) =>
        head = {}
        head.version = @version = buffer[0].toString()
        head.updatedDate = @updatedDate = new Date 1900 + buffer[1], buffer[2] - 1, dd = buffer[3]
        head.recordsCount = @recordsCount = buffer.readUInt32LE 4, true
        head.headOffset = @headOffset = buffer.readUInt16LE 8, true
        head.recordLength = @recordLength = buffer.readUInt16LE 10, true
        head.fields = []
        k = 0
        @fields = for i in [32 .. @headOffset - 32] by 32
            field = 
                name: (@iconv.convert(buffer.slice i, i+11).toString().replace /[\u0000]+$/, '').replace /^[\r]+|[\n]+|[\r\n]+|[\n\r]+/, ''
                type: (String.fromCharCode buffer[i+11]).replace /[\u0000]+$/, ''
                address: buffer.readUInt32LE i+12, true
                length: buffer.readUInt8 i+16
                accuracy: buffer.readUInt8 i+17
            if field.name != ''
                head.fields[k++] = field
            field
        @emit 'head', head

    _parseRecords: (buffer) =>
        endPoint = @headOffset + @recordLength * @recordsCount - 1
        bufferLength = buffer.length
        bufferTemp = null
        # for point=@headOffset; point<endPoint && point<bufferLength; point+=@recordLength
        for point in [@headOffset+1..endPoint] by @recordLength when point < bufferLength
            bufferTemp = buffer.slice point, point+@recordLength
            # console.log "begin:#{point}; end:#{point+@recordLength};"
            record = []
            i = 0
            curPoint = 0
            for field in @fields
                if field.name == ''
                    curPoint+=field.length
                else
                    record[i++] = @_parseField curPoint, curPoint+=field.length, field, bufferTemp
            @emit 'record', record

    _parseField: (begin, end, field, buffer) =>
        switch field.type
            when 'C'
                value = @iconv.convert(buffer.slice begin, end).toString().replace /^\x20+|\x20+$/g, ''
                if value
                    if @timeReg1.test value
                        value = new Date value
                    # if @timeReg2.test value
                    #     yy = parseInt buffer.slice(begin, begin+4)
                    #     mm = parseInt buffer.slice(begin+5, begin+7) - 1
                    #     dd = parseInt buffer.slice(begin+8, begin+10)
                    #     hh = parseInt buffer.slice(begin+11, begin+13)
                    #     value = new Date yy, mm, dd, hh, 0, 0
                else
                    value = null
            when 'N', 'F'
                value = parseFloat (buffer.slice begin, end)
                if isNaN(value)
                    value = null
            when 'L'
                value = buffer.slice(begin, end).toString()
                if value=='Y' or value=='y' or value=='T' or value=='t'
                    value = true
                else if value=='N' or value=='n' or value=='F' or value=='f'
                    value = false
                else value = null
            when 'D'
                yy = parseInt buffer.slice(begin, begin+4)
                mm = parseInt buffer.slice(begin+4, begin+6) - 1
                dd = parseInt buffer.slice(begin+6, begin+8)
                if isNaN(yy)
                    value = null
                else
                    value = new Date(yy, mm, dd) #+ "  " +(buffer.slice begin, end).toString()
            else
                value = (buffer.slice begin, end).toString().replace /^\x20+|\x20+$/g, ''
                if !value
                    value = null
                
        {name: field.name, value: value}

module.exports = DBFParser