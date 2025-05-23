import Lake
open Lake DSL

package «lean_constant_data» where
  -- add package configuration options here

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git"

@[default_target]
lean_exe go where
  root := `Main
  supportInterpreter := true
