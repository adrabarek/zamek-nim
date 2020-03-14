import os, parseopt, strutils, logging, sequtils
import zamek

type
  Command = enum
    none, create, add, remove, edit, tag_add, tag_remove, find, find_by_tags, find_connected
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
        incl(options, Option.verbose)
    else:
      handleInvalidParams()

  if command == Command.none:
    handleInvalidParams()

  (command, arguments, options)

proc doAdd(arguments: Arguments) =
  # validate arguments
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