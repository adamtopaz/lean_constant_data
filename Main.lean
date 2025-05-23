import Mathlib.Lean.CoreM
import ImportGraph.RequiredModules

open Lean

def getProjectSrcSearchPath : IO SearchPath := do
  let srcSearchPath := (← IO.getEnv "LEAN_SRC_PATH")
    |>.map System.SearchPath.parse
    |>.getD []
  let srcPath := (← findSysroot) / "src" / "lean"
  return srcSearchPath ++ [srcPath / "lake", srcPath]

def getSrcForDecl (sp : SearchPath) (name : Name) : 
    CoreM (Option Name × Option Substring) := do 
  let some modName := (← getEnv).getModuleFor? name | return (none, none)
  let some range ← findDeclarationRanges? name | return (modName, none)
  let range := range.range
  try 
    let fpath ← findLean sp modName
    let fsrc ← IO.FS.readFile fpath
    let fileMap : FileMap := .ofString fsrc
    let pos := fileMap.ofPosition range.pos
    let endPos := fileMap.ofPosition range.endPos
    let substring : Substring := .mk fsrc pos endPos
    return (some modName, some substring)
  catch _ => return (some modName, none)

unsafe
def main : IO Unit := IO.FS.withFile "data.jsonl" .write fun handle => do
  initSearchPath (← findSysroot)
  enableInitializersExecution
  let srcSp ← getProjectSrcSearchPath
  CoreM.withImportModules #[`Mathlib] do 
    for (n, _) in (← getEnv).constants do
      println! s!"Processing {n}"
      let (modName, src) ← getSrcForDecl srcSp n
      handle.putStrLn <| Json.compress <| json% {
        name : $n,
        module : $modName,
        src : $(src.map fun s => s.toString)
      }
