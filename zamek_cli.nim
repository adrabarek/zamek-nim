import os, parseopt, times, marshal
import zamek

type
  Command = enum
    none, create, add, remove, edit, tag_add, tag_remove, find, find_by_tags, find_connected

proc handleInvalidParams() =
  echo """usage: zamek [--verbose] [--help] <command> [<args>]

Commands:
  create
  add
  remove
  edit
  tag-add
  tag-remove
  find
  find-by-tags
  find-connected"""
  quit(QuitFailure)

proc processCommandLine() : (Command, zamek.Settings) =
  var args = initOptParser(commandLineParams())  

  var command = Command.none
  var settings: Settings

  for kind, key, val in args.getopt():
    case kind
    of cmdArgument:
      case key
      of "create":
        command = Command.create
      of "add":
        command = Command.add
      of "remove":
        command = Command.remove
      of "edit":
        command = Command.edit
      of "tag-add":
        command = Command.tag_add
      of "tag-remove":
        command = Command.tag_remove
      of "find":
        command = Command.find
      of "find-by-tags":
        command = Command.find_by_tags
      of "find-connected":
        command = Command.find_connected
    of cmdLongOption, cmdShortOption:
      case key:
      of "verbose", "v":
        incl(settings, zamek.SettingFlag.verbose)
    else:
      handleInvalidParams()

  if command == Command.none:
    handleInvalidParams()

  (command, settings)

proc validateDirectory(path: string): bool = 
  for path in walkPattern(path & "/*"):
    var (_, _, ext) = splitFile(path)
    if ext != zamek.noteExtension:
      return false  
  return true

proc backupFile(path: string, maxBackups: int): bool =
    var nTries = 0
    while nTries < maxBackups:
      let backupPath = path & "_backup" & $(now().format("yyyy-MM-dd")) & "_" & $(nTries)
      if not fileExists(backupPath):
        moveFile(path, backupPath)
        break
      inc nTries
    if(nTries == maxBackups):
      return false
    return true

proc doCreate() =
  let zamekDir = joinPath(getCurrentDir(), zamek.dirName)
  let regFilePath = joinPath(zamekDir, zamek.regFileName)

  # verify if this is a valid place for starting a Zamek repository
  if not validateDirectory(getCurrentDir()):
    echo "Zamek repository needs to be created in an empty directory."
    quit(QuitFailure)

  # create zamek control directory if doesn't exist yet
  if not dirExists(zamekDir):
    createDir(zamekDir)

  # backup current zamek registry file if already exists
  if fileExists(regFilePath):
    const maxBackups = 10
    if not backupFile(regFilePath, maxBackups):
      echo "Failed to backup registry file " & regFilePath
      echo "Remove some of the backups under " & zamekDir & " and try again."
      quit(QuitFailure)
    
  var registry = new(zamek.Registry)
  for file in walkPattern(getCurrentDir() & "/*"):
    echo file

  writeFile(regFilePath, "")

proc main() =
  let (command, settings) = processCommandLine()

  if zamek.SettingFlag.verbose in settings:
    echo "Verbose mode on!"
    echo "Running command: ", command

  case command
  of none:
    assert(false, "If no command is set, should exit early - nothing to do.")
  of create:
    doCreate()
  of add:
    let test0 = Note(name: "test_note_0", content: "Test content. This can be markdown or something", tags: @["cow", "dog", "badger"], links: @["test_note_2"])
    let test1 = Note(name: "test_note_1", content: "Test content. Another note.", tags: @["cow", "horse"], links: @["test_note_2"])
    let test2 = Note(name: "test_note_2", content: "Test content. Yet another one.", tags: @["dog", "horse"], links: @["test_note_0", "test_note_1"])
    writeFile(test0.name & zamek.noteExtension, $$test0)
    writeFile(test1.name & zamek.noteExtension, $$test1)
    writeFile(test2.name & zamek.noteExtension, $$test2)
  of remove:
    discard
  of edit:
    discard
  of tag_add:
    discard
  of tag_remove:
    discard
  of find:
    discard
  of find_by_tags:
    discard
  of find_connected:
    discard

main()