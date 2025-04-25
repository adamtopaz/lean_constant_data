namespace HACKATHON

/-- A version of the natural numbers -/
inductive Thing : Type where
  | zero : Thing
  | succ : Thing → Thing

/- A bad comment -/
@[simp]
def Foo := Thing 

instance : Zero Thing where zero := .zero

example : True := sorry
example : True := sorry
