import os
import parseopt

type
  Command = enum
    none, create, add, remove, edit, tag_add, tag_remove, find, find_by_tags, find_connected
  Setting = enum
    verbose
  Settings = set[Setting]

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

proc processCommandLine() : (Command, Settings) =
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
        incl(settings, Setting.verbose)
    else:
      handleInvalidParams()

  if command == Command.none:
    handleInvalidParams()

  (command, settings)

let (command, settings) = processCommandLine()

if Setting.verbose in settings:
  echo "Verbose mode on!"
  echo "Running command: ", command