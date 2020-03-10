import os, parseopt, times
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
      case key
      of "verbose", "v":
        incl(settings, zamek.SettingFlag.verbose)
    else:
      handleInvalidParams()

  if command == Command.none:
    handleInvalidParams()

  (command, settings)

proc doCreate() =
  let zamekDir = joinPath(getCurrentDir(), zamek.dirName)
  let regFilePath = joinPath(zamekDir, zamek.regFileName)

  # verify if this is a valid place for starting a Zamek repository
  if not zamek.validateDirectory(getCurrentDir()):
    echo "Zamek repository needs to be created in an empty directory."
    quit(QuitFailure)

  if not dirExists(zamekDir):
    createDir(zamekDir)

  # backup current zamek registry file if it exists
  if fileExists(regFilePath):
    echo "Registry file already exists!"

    var nTries = 0
    const maxTries = 10
    while nTries < maxTries:
      let regBackupPath = joinPath(getCurrentDir(), zamek.dirName, zamek.regFileName & "_backup" & $(now().format("yyyy-MM-dd")) & "_" & $(nTries))
      if not fileExists(regBackupPath):
        moveFile(regFilePath, regBackupPath)
        break
      nTries += 1

    if(nTries == maxTries):
      echo "Could not create repository - too many registry file backups. Remove some of .zamek/registry_backup files."
      quit(QuitFailure)
    
  # 3 create a Zamek registry instance
  var z = new(Zamek)
  if zamek.create(z):
    echo "Creation successful."
  else:
    echo "Creation failed."
  # 4 add all the .znotes present in the directory to the registry
  # 5 save the new registry
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
    discard
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