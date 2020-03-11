# registry naming: .zamek
# note naming: <name>.znot
const dirName* = ".zamek"
const regFileName* = "registry"
const noteExtension* = ".znot"

type
  SettingFlag* = enum
    verbose
  Settings* = set[SettingFlag]
  Note* = object
    name: string
    content: string
    tags: seq[string]
    links: seq[string]
  Registry* = object
    notes: seq[Note]

proc initRegistry*(registry: ref Registry): bool =
  return true

proc addNote*(registry: ref Registry, note: Note): bool =
  registry.notes.add(note)
  return true