import tables
import sets

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
    links : Table[NoteName, HashSet[NoteName]]
    tags : Table[Tag, HashSet[NoteName]]


proc addNote*(registry: var Registry, note: Note) =
    for tag in note.tags:
      if tag notin registry.tags:
        registry.tags[tag] = HashSet[NoteName]()
      registry.tags[tag].incl(note.name)

    for otherNote in note.links:
      if note.name notin registry.links:
        registry.links[note.name] = HashSet[NoteName]()
      registry.links[note.name].incl(otherNote)
