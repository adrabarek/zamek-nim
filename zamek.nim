import tables

const dirName* = ".zamek"
const regFileName* = "registry"
const noteExtension* = ".znot"

type
  SettingFlag* = enum
    verbose
  Settings* = set[SettingFlag]
  NoteName = string
  Tag = string
  Note* = object
    name*: string
    content*: string
    tags*: seq[Tag]
    links*: seq[NoteName]
  Registry* = object
    links : Table[NoteName, seq[NoteName]]
    tags : Table[Tag, seq[NoteName]]


proc addNote*(registry: var Registry, note: Note) =
   for tag in note.tags:
    if tag in registry.tags:
      registry.tags[tag].add(note.name)
    else:
      registry.tags[tag] = @[note.name]

    for otherNote in note.links:
      if note.name in registry.links:
        registry.links[note.name].add(otherNote)
      else:
        registry.links[note.name] = @[otherNote]