import os

# registry naming: .zamek
# note naming: <name>.znot

type
  SettingFlag* = enum
    verbose
  Settings* = set[SettingFlag]
  Zamek* = ref object

proc validateDirectory*(path: string) : bool =
  for path in walkPattern("*"):
    var (_, _, ext) = splitFile(path)
    if ext != "znot" and ext != "zreg":
      return false  
  return true

proc create*(z: var Zamek) : bool =
  for path in walkPattern("*"):
    discard
  return true