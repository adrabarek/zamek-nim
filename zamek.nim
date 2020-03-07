import os

# registry naming: zamek.zreg
# note naming: <name>.znot

type
  SettingFlag* = enum
    verbose
  Settings* = set[SettingFlag]
  Zamek* = ref object

proc create*(z: var Zamek) : bool =
  for path in walkPattern("*"):
    var (dir, name, ext) = splitFile(path)
    if ext != "znot" and ext != "zreg":
      echo "The directory has files in it that are not zamek files."
      return false
  return true