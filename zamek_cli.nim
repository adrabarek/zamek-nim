import os, parseopt, strutils, logging, sequtils
import zamek

type
  Command = enum
    none, create, add, remove, set_content, tag_add, tag_remove, find, find_by_tags, find_connected
  Arguments = seq[string]
  Option = enum
    verbose

proc cleanUpString(s: string): string =
  strip(s).strip(chars = {','})

proc cleanUpArgs(args: var seq[string]) =
  apply(args, proc (x: var string) = 
    x = cleanUpString(x))
  keepIf(args, proc (x: string): bool = 
    x != "")

proc handleInvalidParams() =
  echo """usage: zamek [--verbose] [--help] <command> [<args>]

Commands:
  create
  add
    <name> <tags> <links> [<content>]
    name    - The name of the note.
    tags    - Comma separated list of tags, e. g. "tag0, tag1, tag2"
    links   - Comma separated list of note names to link to, e. g. "note0, note1, note2"
    content - String containing content of the note. If not present, stdin is used.

    Adds a note to Zamek.
  remove
    <name>  
    name    - The name of the note to be removed.

    Removes a note from Zamek.
  get
    <name>
    name    - The name of the note to be printed.

    Prints a note in JSON format.
  set-content
    <name> <content>
    name    - The name of the note that will be modified.
    content - New content of the note.

    Sets content of given note.
  tag-add
    <name> <tags>
    name    - The note that will have the tags added.
    tags    - Comma separated list of tags, e. g. "tag0, tag1, tag2"
  tag-remove
  link-add
    <first name> <second name>

    Adds a link between two notes.
  link-remove
    <first name> <second name>
  find
  find-by-tags
  find-connected"""
  quit(QuitFailure)

proc processCommandLine() : (Command, Arguments, set[Option]) =
  var args = initOptParser(commandLineParams())  

  var command = Command.none
  var arguments: seq[string]
  var options: set[Option]

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
      of "set-content":
        command = Command.set_content
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
        incl(options, Option.verbose)
    else:
      handleInvalidParams()

  if command == Command.none:
    handleInvalidParams()

  (command, arguments, options)

proc loadNoteAndRegistry(noteName: string, note: var Note, registry: var Registry): bool =
  if not zamek.loadNote(getCurrentDir(), noteName, note) or not loadRegistry(getCurrentDir(), registry):
    error("Cannot retrieve note ", noteName, " or load Zamek registry.")
    return false
  return true

proc doAdd(arguments: Arguments) =
  if len(arguments) != 4 and len(arguments) != 3:
    error("Wrong number of arguments for add command.")
    handleInvalidParams()

  var note: Note
  note.name = cleanUpString(arguments[0])

  note.tags = arguments[1].split(", ")
  cleanUpArgs(note.tags)

  note.links = arguments[2].split(", ")
  cleanUpArgs(note.links)

  if len(arguments) == 4:
    # content comes from argument
    note.content = arguments[3]
  else:
    # content comes from stdin
    note.content = readAll(stdin)

  if not zamek.addNote(getCurrentDir(), note):
    quit(QuitFailure)

proc doRemove(arguments: Arguments) =
  if len(arguments) != 1:
    error("Wrong number of arguments for remove command.")
    handleInvalidParams()

  let noteName = cleanUpString(arguments[0])

  var note: Note
  var registry: Registry
  if not loadNoteAndRegistry(noteName, note, registry):
    quit(QuitFailure)

  zamek.removeNote(getCurrentDir(), registry, note)

  info("Succesfully removed note ", noteName)

proc doSetContent(arguments: Arguments) =
  if len(arguments) != 2:
    error("Wrong number of arguments for set-content command.")
    handleInvalidParams()

  let noteName = cleanUpString(arguments[0])
  var note: zamek.Note
  if not zamek.loadNote(getCurrentDir(), noteName, note):
    error("Failed to set note content - couldn't retrieve note.")

  note.content = cleanUpString(arguments[1])
  if not zamek.saveNote(getCurrentDir(), note):
    error("Failed to save note.")

  info("Succesfully saved new content of note: ", note)

proc doAddTag(arguments: Arguments) =
  if len(arguments) != 2:
    error("Wrong number of arguments for tag-add command.")
    handleInvalidParams()

  let noteName = cleanUpString(arguments[0])

  var note: Note
  var registry: Registry
  if not loadNoteAndRegistry(noteName, note, registry):
    quit(QuitFailure)

  var newTags = arguments[1].split(", ")
  cleanUpArgs(newTags)
  note.tags = note.tags & newTags
  zamek.updateTags(registry, note)
  if not zamek.saveNote(getCurrentDir(), note):
    error("Failed to save note: ", note.name)
  if not zamek.saveRegistry(getCurrentDir(), registry):
    error("Failed to save repository.")

  info("Successfully added tags to note: ", note)

proc main() =
  let (command, arguments, options) = processCommandLine()

  addHandler(newConsoleLogger(if Option.verbose in options: lvlAll else: lvlError))

  case command
  of none:
    assert(false, "If no command is set, should exit early - nothing to do.")
  of create:
    if not zamek.createRepository(getCurrentDir()):
      error("Failed to create Zamek repository.")
      quit(QuitFailure)
  of add:
    doAdd(arguments)
  of remove:
    doRemove(arguments)
  of set_content:
    doSetContent(arguments)
  of tag_add:
    doAddTag(arguments)
  of tag_remove:
    discard
  of find:
    discard
  of find_by_tags:
    discard
  of find_connected:
    discard

main()