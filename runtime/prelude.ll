target triple = "x86_64-pc-linux-gnu"

;; we want malloc
declare noalias i8* @malloc(i64) nounwind

%struct.pyret-value = type { i32, i32, i8* }