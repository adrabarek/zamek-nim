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

    # Dodawanie notatki
    #   zamek add <tytuł>
    # Usuwanie notatki
    #   zamek remove <tytuł>/<hash>
    # Edytowanie notatki
    #   zamek edit <tytuł>
    # Dodanie tagów do notatki
    #   zamek tag-add <tytuł>/<hash> <tag>...
    # Usunięcie tagów z notatki
    #   zamek tag-remove <tytuł>/<hash> <tag>...
    # Szukanie notatek po tagach
    #   zamek find-by-tags <tag>...
    # Szukanie notatek po treści
    #   zamek find tresc
    # Szukanie notatek po połączeniach
    #   zamek find-connected <tytuł>/<hash> <connection distance, default 1>
    # Utworzenie rejestru (pozwala też ponownie wykreować rejestr na podstawie obecnych plików):
    #   zamek create
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