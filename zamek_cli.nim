import os
import parseopt

proc handleInvalidParams() =
  echo "Usage: zamek COMMAND TARGET..."
  quit(QuitFailure)

if paramCount() < 1:
  handleInvalidParams()

var args = initOptParser(commandLineParams())

args.next()
if args.kind != cmdArgument:
  handleInvalidParams()

case args.key
of "create":
  echo "Creating a new notes repository."
of "add":
  echo "Adding new note."
of "remove":
  echo "Removing a note."
of "edit":
  echo "Editing a note."
of "tag-add":
  echo "Adding a tag to a note."
of "tag-remove":
  echo "Removing a tag from a note."
of "find":
  echo "Finding notes by content search."
of "find-by-tags":
  echo "Finding notes by tags."
of "find-connected":
  echo "Findinc connected notes."