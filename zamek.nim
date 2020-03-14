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
  Registry = object
    links : Table[NoteName, HashSet[NoteName]]
    tags : Table[Tag, HashSet[NoteName]]
  Paths = object
    zamekDir: string
    registryFilePath: string

proc createPaths(root: string): Paths =
  let zamekDir = joinPath(root, zamek.dirName)
  let registryFilePath = joinPath(zamekDir, zamek.registryFileName)
  Paths(zamekDir: zamekDir, registryFilePath: registryFilePath)

proc backupFile(path: string, maxBackups: int): bool =
    var nTries = 0
    while nTries < maxBackups:
      let backupPath = path & "_backup" & $(now().format("yyyy-MM-dd")) & "_" & $(nTries)
      if not fileExists(backupPath):
        moveFile(path, backupPath)
        break
      inc nTries
    if(nTries == maxBackups):
      return false
    return true

proc onlyZamekFilesPresent(path: string): bool = 
  for path in walkPattern(path & "/*"):
    var (_, _, ext) = splitFile(path)
    if ext != zamek.noteExtension:
      return false
  return true

proc isZamekDirectory(path: string): bool =
  dirExists(joinPath(path, zamek.dirName)) and onlyZamekFilesPresent(path)

proc addNote(registry: var Registry, note: Note): bool =
  for tag in note.tags:
    if tag notin registry.tags:
      registry.tags[tag] = HashSet[NoteName]()
    registry.tags[tag].incl(note.name)

  for otherNote in note.links:
    if note.name notin registry.links:
      registry.links[note.name] = HashSet[NoteName]()
    registry.links[note.name].incl(otherNote)

  return true

proc addNote*(root: string, note: Note): bool =
    if not isZamekDirectory(root):
      error("Not a valid Zamek directory. Initialize one using create command.")
      return false

    let notePath = joinPath(root, note.name & zamek.noteExtension)

    if fileExists(notePath):
      error("Cannot add note - note with that name already exists.")
      return false

    writeFile(notePath, $$(note))
    setFilePermissions(notePath, {fpUserRead, fpGroupRead, fpOthersRead})

    let paths = createPaths(root)
    var registry = to[zamek.Registry](readFile(paths.registryFilePath))
    if not addNote(registry, note):
      error("Failed to add note to the registry.")
      return false
    writeFile(paths.registryFilePath, $$(registry))

    info("Successfuly added Zamek note.")
    return true

proc createRepository*(root: string): bool =
  let paths = createPaths(root)

  if not onlyZamekFilesPresent(root):
    error("Zamek repository needs to be created in an empty directory or a previous Zamek repository.")
    return false

  # create zamek control directory if doesn't exist yet
  if not dirExists(paths.zamekDir):
    createDir(paths.zamekDir)

  var registry: zamek.Registry
  for file in walkPattern(getCurrentDir() & "/*"):
    # add note to the registry
    var note = to[Note](readFile(file))
    if not addNote(registry, note):
      error("Failed to add present note to new repository. Aborting.")
      return false
    # make the note file read-only
    setFilePermissions(file, {fpUserRead, fpGroupRead, fpOthersRead})

  # backup current zamek registry file if already exists
  if fileExists(paths.registryFilePath):
    const maxBackups = 10
    if not backupFile(paths.registryFilePath, maxBackups):
      error("Failed to backup registry file " & paths.registryFilePath)
      error("Remove some of the backups under " & paths.zamekDir & " and try again.")
      return false

  # save the registry file
  writeFile(paths.registryFilePath, $$registry)

  info("Successfuly created Zamek repository.")
  return true;