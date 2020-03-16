import os, tables, sets, marshal, times, logging

const dirName = ".zamek"
const registryFileName = "registry"
const noteExtension = ".znot"

type
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
  Paths = object
    zamekDir: string
    registryFilePath: string

proc createZamekPaths(root: string): Paths =
  let zamekDir = joinPath(root, zamek.dirName)
  let registryFilePath = joinPath(zamekDir, zamek.registryFileName)
  Paths(zamekDir: zamekDir, registryFilePath: registryFilePath)

proc createNotePath(root: string, noteName: string): string =
  joinPath(root, noteName & zamek.noteExtension)

proc backupFile(path: string, maxBackups: int): bool =
    var nTries = 0
    while nTries < maxBackups:
      let backupPath = path & "_backup" & $(now().format("yyyy-MM-dd")) & "_" & $(nTries)
      if not fileExists(backupPath):
        info("File \"", path, "\" backed up as \"", backupPath, "\"")
        moveFile(path, backupPath)
        break
      inc nTries
    if(nTries == maxBackups):
      return false
    return true

proc isZamekDirectory(path: string): bool =
  dirExists(joinPath(path, zamek.dirName))

proc loadRegistry*(root: string, registry: var Registry): bool =
  let paths = createZamekPaths(root)
  try:
    registry = to[zamek.Registry](readFile(paths.registryFilePath))
  except IOError:
    error("Failed to load registry - IO error.")
    return false
  return true

proc saveRegistry*(root: string, registry: Registry): bool =
  let paths = createZamekPaths(root)
  try:
    writeFile(paths.registryFilePath, $$(registry))
  except IOError:
    error("Failed to save registry - IO error.")
    return false
  return true

proc updateTags*(registry: var Registry, note: Note) =
  for tag in note.tags:
    if tag notin registry.tags:
      info("Tag ", tag, " used for the first time.")
      registry.tags[tag] = HashSet[NoteName]()
    registry.tags[tag].incl(note.name)

proc updateLinks*(registry: var Registry, note: Note) =
  for otherNote in note.links:
    if note.name notin registry.links:
      registry.links[note.name] = HashSet[NoteName]()
    if otherNote notin registry.links:
      registry.links[otherNote] = HashSet[NoteName]()
    registry.links[note.name].incl(otherNote)
    registry.links[otherNote].incl(note.name)

proc addNote(registry: var Registry, note: Note, root: string): bool =
  for otherNote in note.links:
    if not fileExists(createNotePath(root, otherNote)):
      error("Trying to link note ", note.name, " to ", otherNote, " which doesn't exist.")
      return false;

  updateTags(registry, note)
  updateLinks(registry, note)

  return true

proc removeNote*(root: string, registry: var Registry, note: Note) =
  for otherNoteName in registry.links[note.name]:
    registry.links[otherNoteName].excl(note.name)
  registry.links.del(note.name)

  for tag in note.tags:
    registry.tags[tag].excl(note.name)
    if registry.tags[tag].len() == 0:
      registry.tags.del(tag)

  removeFile(createNotePath(root, note.name))

  info("Removed note ", note.name, " from Zamek.")

proc loadNote*(root: string, noteName: string, note: var Note): bool = 
  let notePath = createNotePath(root, noteName)
  if not fileExists(notePath):
    error("Cannot retrieve note ", noteName, " - the file doesn't exist.")
    return false
  try:
    note = to[zamek.Note](readFile(notePath))
  except IOError:
    error("Failed to load note, IO error.")
    return false
  return true

proc saveNote*(root: string, note: Note): bool =
  let notePath = createNotePath(root, note.name)
  try:
    if fileExists(notePath):
      setFilePermissions(notePath, {fpUserWrite, fpGroupWrite, fpOthersWrite})
    writeFile(notePath, $$(note))
    setFilePermissions(notePath, {fpUserRead, fpGroupRead, fpOthersRead})
  except IOError:
    error("Failed to write note file - IO error.")
    return false
  except OSError:
    error("Failed to write note file - OS error.")
    return false
  return true

proc addNote*(root: string, note: Note): bool =
  if not isZamekDirectory(root):
    error("Not a valid Zamek directory. Initialize one using create command.")
    return false

  let notePath = createNotePath(root, note.name)

  if fileExists(notePath):
    error("Cannot add note - note with that name already exists.")
    return false

  if not saveNote(root, note):
    error("Failed to save note ", note.name)
    return false

  var registry: Registry
  if not loadRegistry(root, registry):
    error("Failed to add note - couldn't load registry")
    return false

  if not registry.addNote(note, root):
    error("Failed to add note to the registry.")
    return false

  if not saveRegistry(root, registry):
    error("Failed to add note - registry couldn't be saved.")
    return false

  info("Successfuly added Zamek note: ", note)
  return true

proc createRepository*(root: string): bool =
  let paths = createZamekPaths(root)

  # create zamek control directory if doesn't exist yet
  if not dirExists(paths.zamekDir):
    createDir(paths.zamekDir)

  var registry: Registry

  for file in walkPattern(getCurrentDir() & "/*" & noteExtension):
    # add note to the registry
    var note = to[Note](readFile(file))
    if not registry.addNote(note, root):
      error("Failed to add present note to new repository. Aborting.")
      return false
    # make the note file read-only
    setFilePermissions(file, {fpUserRead, fpGroupRead, fpOthersRead})

  # backup current zamek registry file if already exists
  if fileExists(paths.registryFilePath):
    const maxBackups = 10
    if not backupFile(paths.registryFilePath, maxBackups):
      error("Failed to backup registry file ", paths.registryFilePath, ". The command will have no effect.")
      return false

  if not saveRegistry(root, registry):
    error("Failed to create repository - registry couldn't be saved.")
    return false

  info("Successfuly created Zamek repository.")
  return true;