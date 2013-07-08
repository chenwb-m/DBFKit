exports.makeSuffix = (fileName, suffix)->
    suffix = "."+suffix if (suffix.indexOf ".") == -1
    suffixIdx = fileName.lastIndexOf "."
    if suffixIdx == -1
        return fileName + suffix
    else
        if suffix.toLowerCase() == (fileName.substring suffixIdx).toLowerCase()
            return fileName
        else
            return fileName + suffix
        
    