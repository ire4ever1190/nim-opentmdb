type
    QuestionType* = enum
        Both = ""
        MultipleChoice = "multiple"
        Boolean = "boolean"

    Difficulty* {.pure.} = enum
      Any    = ""
      Easy   = "easy"
      Medium = "medium"
      Hard   = "hard"
