import os
import argparse

def replaceValue(content, nameStr: str, oldValueStr: str, newValueStr: str):
    name = nameStr.encode('utf8')
    oldValue = oldValueStr.encode('utf8')
    newValue = newValueStr.encode('utf8')
    if oldValue == newValue:
        return None
    nameIndex = content.find(name)
    if nameIndex == -1:
        return None
    start = content[:nameIndex+len(name)]
    remaining = content[nameIndex+len(name):]
    colonIndex = remaining.find(":".encode('utf8'))
    valLen = int(remaining[:colonIndex])
    if valLen < len(oldValue):
        return None
    remaining = remaining[colonIndex+1:]
    actualValue = remaining[:valLen]
    if valLen == len(oldValue) and not actualValue.startswith(oldValue):
        return None
    if valLen > len(oldValue) and not actualValue.startswith(oldValue + "/".encode('utf8')):
        return None
    newLen = valLen - len(oldValue) + len(newValue)
    remaining = remaining[len(oldValue):]
    result = start + str(newLen).encode('utf8') + ":".encode('utf8') + newValue + remaining
    return result

def replaceInFile(filepath: str, values):
    content: str
    with open(filepath, 'rb') as file:
        content = file.read()
    changes = False
    for value in values:
        replaced = replaceValue(content, value[0], value[1], value[2])
        if replaced is not None:
            content = replaced
            changes = True
    if changes:
        print("updating paths in file", filepath)
        with open(filepath, 'wb') as file:
            file.write(content)

def updateFilesInDirectory(directoryPath, values):
    for file in os.listdir(os.fsencode(directoryPath)):
        filename = os.fsdecode(file)
        if not filename.endswith(".fastresume"):
            continue
        replaceInFile(directoryPath + "/" + filename, values)

def run():
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", help="Directory to search for .fastresume files", type=str)
    parser.add_argument('--value',action='append',nargs=3,
        metavar=('name','old','new'),help='can be repeated')
    args = parser.parse_args()
    directoryPath = args.directory
    if directoryPath == None:
        return 1
    if args.value == None:
        return 1

    updateFilesInDirectory(directoryPath, args.value)

if __name__ == "__main__":
    result = run()
    if result != None:
        exit(result)
