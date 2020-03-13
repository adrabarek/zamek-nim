import os, parseopt, times, marshal, strutils
import zamek

type
  Command = enum
    none, create, add, remove, edit, tag_add, tag_remove, find, find_by_tags, find_connected
  Arguments = seq[string]
  Paths = object
    zamekDir: string
    registryFilePath: string

proc handleInvalidParams() =
  echo """usage: zamek [--verbose] [--help] <command> [<args>]

Commands:
  create
  add
    <name> <tags> <links> [<content>]
    name - The name of the note. Best use snake_case convention.
    tags - Comma separated list of tags, e. g. "tag0, tag1, tag2"
    links - Comma separated list of note names to link to, e. g. "note0, note1, note2"
    content - String containing content of the note. If not present, stdin is used.
  remove
  edit
  tag-add
  tag-remove
  find
  find-by-tags
  find-connected"""
  quit(QuitFailure)

proc processCommandLine() : (Command, Arguments, zamek.Settings) =
  var args = initOptParser(commandLineParams())  

  var command = Command.none
  var arguments: seq[string]
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
      else:
        arguments.add(key)
    of cmdLongOption, cmdShortOption:
      case key:
      of "verbose", "v":
        incl(settings, zamek.SettingFlag.verbose)
    else:
      handleInvalidParams()

  if command == Command.none:
    handleInvalidParams()

  (command, arguments, settings)

proc onlyZamekFilesPresent(path: string): bool = 
  for path in walkPattern(path & "/*"):
    var (_, _, ext) = splitFile(path)
    if ext != zamek.noteExtension:
      return false
  return true

proc isZamekDirectory(path: string): bool =
  dirExists(joinPath(path, zamek.dirName)) and onlyZamekFilesPresent(path)

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

proc doCreate(paths: Paths) =
  # verify if this is a valid place for starting a Zamek repository
  if not onlyZamekFilesPresent(getCurrentDir()):
    echo "Zamek repository needs to be created in an empty directory or a previous Zamek repository."
    quit(QuitFailure)

  # create zamek control directory if doesn't exist yet
  if not dirExists(paths.zamekDir):
    createDir(paths.zamekDir)

  # create the registry
  var registry: zamek.Registry
  for file in walkPattern(getCurrentDir() & "/*"):
    # add note to the registry
    var note = to[Note](readFile(file))
    registry.addNote(note)
    # make the note file read-only
    setFilePermissions(file, {fpUserRead, fpGroupRead, fpOthersRead})

  # backup current zamek registry file if already exists
  if fileExists(paths.registryFilePath):
    const maxBackups = 10
    if not backupFile(paths.registryFilePath, maxBackups):
      echo "Failed to backup registry file " & paths.registryFilePath
      echo "Remove some of the backups under " & paths.zamekDir & " and try again."
      quit(QuitFailure)

  # save the registry file
  writeFile(paths.registryFilePath, $$registry)

proc toSnakeCase(s: string): string =
  toLowerAscii(strip(s)).replace(" ", "_")

proc doAdd(paths: Paths, arguments: Arguments) =
  # validate arguments
  if len(arguments) != 4 and len(arguments) != 3:
    echo "Wrong number of arguments for add command."
    handleInvalidParams()

  if not isZamekDirectory(getCurrentDir()):
    echo "Not a valid Zamek directory. Initialize one using create command."
    quit(QuitFailure)

  var note: Note
  note.name = toSnakeCase(arguments[0])

  note.tags = arguments[1].split(", ")
  for i, tag in note.tags:
    note.tags[i] = toSnakeCase(tag)

  note.links = arguments[2].split(", ")
  for i, link in note.links:
    note.links[i] = toSnakeCase(link)

  if len(arguments) == 4:
    # content comes from argument
    note.content = arguments[3]
  else:
    # content comes from stdin
    note.content = readAll(stdin)

  let notePath = joinPath(getCurrentDir(), note.name & zamek.noteExtension)
  if fileExists(notePath):
    echo "Cannot add note - note with that name already exists."
    quit(QuitFailure)
  writeFile(notePath, $$(note))
  setFilePermissions(notePath, {fpUserRead, fpGroupRead, fpOthersRead})

  var registry = to[zamek.Registry](readFile(paths.registryFilePath))
  registry.addNote(note)
  writeFile(paths.registryFilePath, $$(registry))

proc createPaths(): Paths =
  let zamekDir = joinPath(getCurrentDir(), zamek.dirName)
  let registryFilePath = joinPath(zamekDir, zamek.regFileName)
  Paths(zamekDir: zamekDir, registryFilePath: registryFilePath)

proc main() =
  let (command, arguments, settings) = processCommandLine()

  if zamek.SettingFlag.verbose in settings:
    echo "Verbose mode on!"
    echo "Running command: ", command

  let paths = createPaths()

  case command
  of none:
    assert(false, "If no command is set, should exit early - nothing to do.")
  of create:
    doCreate(paths)
  of add:
    doAdd(paths, arguments)
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