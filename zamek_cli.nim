import os
import parseopt
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

let (command, settings) = processCommandLine()

if zamek.SettingFlag.verbose in settings:
  echo "Verbose mode on!"
  echo "Running command: ", command

case command
of none:
  assert(false, "If no command is set, should exit early - nothing to do.")
of create:
  # 1 verify if this is a valid place for starting a Zamek repository
  if not zamek.validateDirectory(getCurrentDir()):
    echo "Zamek repository needs to be created in an empty directory."
    quit(QuitFailure)
  # 2 backup current zamek registry file if it exists
  # 3 create a Zamek registry instance
  # 4 add all the .znotes present in the directory to the registry
  # 5 save the new registry
  var z = new(Zamek)
  if zamek.create(z):
    echo "Creation successful."
  else:
    echo "Creation failed."
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