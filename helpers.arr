#lang pyret

provide *

import file as F

fun flatten(alol):
  for fold(base from [], current from alol):
    base.append(current)
  end
end

data Pair<A,B>:
  | pair(a :: A, b :: B)
end

fun get-file-text(filename :: String) -> String:
    f = F.input-file(filename)
    prog-txt = f.read-file()
    f.close-file()
    prog-txt
end

fun put-file-text(filename :: String, txt :: String):
    f = F.output-file(filename, false)
    f.display(txt)
    f.close-file()
end
