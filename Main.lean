import Lean
import Lean.Util.Path

--import LeanConstantData

open Lean

def getSrcSearchPath : IO SearchPath := do
  let srcSearchPath := (← IO.getEnv "LEAN_SRC_PATH")
    |>.map System.SearchPath.parse
    |>.getD []
  let srcPath : System.FilePath := 
    "/home/adam/.elan/toolchains/leanprover--lean4---v4.19.0-rc3/src/lean"
--  let srcPath := (← IO.appDir) / ".." / "src" / "lean"
  -- `lake/` should come first since on case-insensitive file systems, Lean thinks that `src/` also contains `Lake/`
  return srcSearchPath ++ [srcPath / "lake", srcPath]

def isBlackListed {m} [Monad m] [MonadEnv m] (declName : Name) : m Bool := do
  if declName == ``sorryAx then return true
  if declName matches .str _ "inj" then return true
  if declName matches .str _ "noConfusionType" then return true
  let env ← getEnv
  pure <| declName.isInternalDetail
   || isAuxRecursor env declName
   || isNoConfusion env declName
  <||> isRec declName <||> Meta.isMatcher declName

def main : IO Unit := do
  let srcSearchPath := (← IO.getEnv "LEAN_SRC_PATH")
  println! srcSearchPath
  let srcPath ← getSrcSearchPath
  println! srcPath
  initSearchPath (← findSysroot)
  unsafe enableInitializersExecution
  let env ← importModules #[.mk `Lean false] {}
  let ctx : Core.Context := { fileName := "<input>", fileMap := default }
  let state : Core.State := { env := env }
  discard <| Core.CoreM.toIO (ctx := ctx) (s := state) (α := Unit) do
    let mut counter := 0
    for (n, _) in (← getEnv).constants do
      if ← isBlackListed n then continue
      let some range ← findDeclarationRanges? n | continue
      let range := range.range
      let some modIdx := Environment.getModuleIdxFor? (← getEnv) n | continue
      let some modName := (← getEnv).base.header.moduleNames[modIdx]? | continue
      let f ← findLean srcPath modName
      let src ← IO.FS.readFile f
      let fileMap : FileMap := .ofString src
      let pos := fileMap.ofPosition range.pos
      let endPos := fileMap.ofPosition range.endPos
      let substring : Substring := .mk src pos endPos
      println! "==="
      println! s!"Name: {n}\n{substring}"
      counter := counter + 1
      if counter == 10 then break

#exit 

#eval show CoreM Unit from do
  let env ← getEnv
  for (n, _) in env.constants do
    --if n.isImplementationDetail then continue
    --println! n
    _



def main : IO Unit := do
  let file ← LeanFile.read "Test.lean"
  file.withInfoTrees fun trees => do for fulltree in trees do 
    match fulltree with 
    | .context ctx (.node (.ofCommandInfo info) tree) => 
      println! info.stx.prettyPrint
    | _ => pure ()
    --println! ← fulltree.format
    println! "---"
    fulltree.visitM' (preNode := fun _ _ _  => pure true) fun ctxInfo info children => do 
      match info with 
      | .ofTermInfo info => 
        if info.elaborator == .anonymous then return
        match info.expr with
        | .const nm _ => println! nm ; println! "---"
        | _ => return
      | _ => return


def main : IO Unit := do
  let file ← LeanFile.read "Test.lean"
  file.withInfoTrees fun trees => do for fulltree in trees do 
    match fulltree with 
    | .context ctx (.node (.ofCommandInfo info) children) => 
      let some ctx := ctx.mergeIntoOuter? none | continue
      unless info.elaborator == `Lean.Elab.Command.elabDeclaration do continue
      --println! info.stx[1][1][0]
      println! info.stx.prettyPrint
      println! "==="
      println! ← fulltree.format
      println! "==="
    | _ => continue

#eval main
