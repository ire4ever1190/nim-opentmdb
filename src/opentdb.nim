import httpclient
import asyncdispatch
import json
import uri

# I wrote this code when I first started Nim and is not the standard that I do now

const
  BASE_URL* = "https://opentdb.com/"
  URL_API* = BASE_URL & "api.php"
  URL_COUNT* = BASE_URL & "api_count.php?category="
  URL_COUNT_GLOBAL* = BASE_URL & "api_count_global.php"
  URL_TOKEN_API* = BASE_URL & "api_token.php"


type
  Question* = object
    ## Contains info for a question
    ##
    ## * **correct_answer**: The right answer for the question
    ## * **incorrect_answers**: The possible answers that are wrong
    category: Category
    kind*: QuestionType
    difficulty*: Difficulty
    question*: string
    correct_answer*: string
    incorrect_answers*: seq[string]
    
  Category* {.pure.} = enum
    Any         = (8, "Any Category")
    General     = (9, "General Knowledge")
    Books       = (10, "Entertainment: Books")
    Film        = (11, "Entertainment: Film")
    Music       = (12, "Entertainment: Music")
    Theatre     = (13, "Entertainment: Musicals & Theatres")
    TV          = (14, "Entertainment: Television")
    VideoGames  = (15, "Entertainment: Video Games")
    BoardGames  = (16, "Entertainment: Board Games")
    Nature      = (17, "Science & Nature")
    Computers   = (18, "Science: Computers")
    Maths       = (19, "Science: Mathematics")
    Mythology   = (20, "Mythology")
    Sports      = (21, "Sports")
    Geography   = (22, "Geography")
    History     = (23, "History")
    Politics    = (24, "Politics")
    Art         = (25, "Art")
    Celebrities = (26, "Celebrities")
    Animals     = (27, "Animals")
    Vehicles    = (28, "Vehicles")
    Comics      = (29, "Entertainment: Comics")
    Gadgets     = (30, "Science: Gadgets")
    Anime       = (31, "Entertainment: Japanese Anime & Manga")
    Cartoons    = (32, "Entertainment: Cartoon & Animations")
    
  QuestionCount* = object
    ## Contains counts for number of questions in a single Category_
    total_question_count*: int
    total_easy_question_count*: int
    total_medium_question_count*: int
    total_hard_question_count*: int

  GlobalCount* = object
    ## Contains total counts for everything in openTDB's database
    total_num_of_questions*: int
    total_num_of_pending_questions*: int
    total_num_of_verified_questions*: int
    total_num_of_rejected_questions*: int    

  QuestionType* = enum
    ## * **multiple**: Multiple choice questions
    ## * **Boolean**: yes/no questions
    ## * **Both**: Both of those
    MultipleChoice = "multiple"
    Boolean = "boolean"
    Both = ""

  Difficulty* {.pure.} = enum
    Any    = ""
    Easy   = "easy"
    Medium = "medium"
    Hard   = "hard"

type
  InvalidParameter = IOError
  NoResults* = IOError
    ## Thrown when you ask for too many questions
  TokenNotFound* = IOError
    ## Thown when token provided isn't valid. Tokens must be made with createToken_
  TokenEmpty* = IOError
    ## Thrown when token has run out of questions and needs to be reset (with resetToken_)

## This package is a wrapper around [opentdb](https://opentdb.com) which provides 
## a database of trivia questions.
##
## This package adds `procs` that can be used ontop of `HttpClient`/`AsyncHttpClient` to get questions from it
##
runnableExamples "-r:off":
  let client = newHttpClient()

  # See getQuestions for more options such as difficulty and categories
  for question in client.getQuestions():
    echo question

  close client

## Using a token is recommended so that you get unique questions in each call (until you run out of questions)
runnableExamples "-r:off":
  let client = newHttpClient()
  var token = client.createToken()
  while true:
    try:
      for question in client.getQuestions(token=token):
        echo question.question, "?"
        echo "Answer: ", question.correct_answer
    except TokenEmpty:
      client.resetToken(token)

proc getQuestions*(client: HttpClient | AsyncHttpClient, category = Category.Any, 
                   difficulty = Difficulty.Any, questionType = Both, 
                   amount: Natural = 10, token = ""): Future[seq[Question]] {.multisync.} =
  ## Gets questions from https://opentdb.com 
  runnableExamples "-r:off":
    let client = newHttpClient()
    # Get questions with default parameters
    let questions = client.getQuestions()
    # Get questions that are easy
    let easyQuestions = client.getQuestions(difficulty=Easy)
    # Get questions in relation to TV
    let tvQuestions = client.getQuestions(category=TV)
    # Get 100 questions
    let hundredQuestions = client.getQuestions(amount=100)
    # You can also combine them
    let combinationQuestions = client.getQuestions(difficulty=Easy, category=TV, amount=100)
  #==#          
  let queryString = encodeQuery({
      "amount": $amount,
      "difficulty": $difficulty,
      "category": if category == Category.Any: "" else: $ord(category),
      "encode": "url3986"
  })
  let
    body = await client.getContent(URL_API & "?" & queryString)
    jsonBody = parseJson(body)

  case jsonBody["response_code"].getInt():
  of 1:
    raise NoResults.newException("No Results: This could be because you were asking for too many questions")
  of 2:
    raise InvalidParameter.newException("Invalid Parameter: Please make a bug report for this and show this in the issue " & queryString)
  of 3:
    raise TokenNotFOund.newException("Token Not Found: You probably have not created the token, please use the createToken proc to get one")
  of 4:
    raise TokenEmpty.newException("Token Empty: You have gotten all the possible questions and so you need to reset the token")
  else: 
    # Manually parse the objects so we can decode the url encoding
    result = newSeqOfCap[Question](jsonBody["results"].len)
    for res in jsonBody["results"]:
      var newQuestion = Question(
        # Old nim verions don't have parseEnum so we do this hack instead
        category: res["category"].str.decodeUrl().`%`.to(Category),
        kind: res["type"].to(QuestionType),
        difficulty: res["difficulty"].to(Difficulty),
        question: res["question"].str.decodeUrl(),
        correct_answer: res["correct_answer"].str.decodeUrl()
      )
      for answer in res["incorrect_answers"]:
        newQuestion.incorrect_answers &= answer.str.decodeUrl()
      result &= newQuestion
                

proc size*(client: HttpClient|AsyncHttpClient, category: Category): Future[QuestionCount] {.multisync.} =
    ## Returns the numbers of questions in a category
    runnableExamples "-r:off":
      import httpclient
      let client = newHttpClient()
      echo client.size(TV).totalQuestionCount
    #==#
    if category == Category.Any:
        raise ValueError.newException("Category cannot be Any, please use totalSize to get that")
    let url = URL_COUNT & $ord(category)
    let response = await client.getContent(url)
    return parseJson(response)["category_question_count"].to(QuestionCount)

proc totalSize*(client: HttpClient|AsyncHttpClient): Future[GlobalCount] {.multisync.} =
    ## Returns the number of questions in total that opentdb has
    runnableExamples "-r:off":
      let client = newHttpClient()
      echo client.totalSize().totalNumOfQuestions
    #==#
    let url = URL_COUNT_GLOBAL
    let response = await client.getContent(url)
    return parseJson(response)["overall"].to(GlobalCount)

proc createToken*(client: HttpClient|AsyncHttpClient): Future[string] {.multisync.} =
    ## Creates a token which makes sure you do not get the same questions twice
    ## After a while you will run out of responses and will need to reset the token
    runnableExamples "-r:off":
      let 
        client = newHttpClient()
        token = client.createToken()
      # Token assures that you won't get the same questions twice
      for qA in client.getQuestions(token=token):
        for qB in client.getQuestions(token=token):
          assert qA != qB
    #==#
    const url = URL_TOKEN_API & "?command=request"
    let response = await client.getContent(url)
    result = parseJson(response)["token"].getStr()

proc resetToken*(client: HttpClient|AsyncHttpClient, token: string) {.multisync.} =
    ## Resets a token so it can reuse questions
    # discard await is used so that it makes sure the token is reset before returning to the user
    runnableExamples "-r:off":
      import httpclient
      let client = newHttpClient()
      let token = client.createToken()
      # Run code that uses up all the questions
      client.resetToken(token)
    #==#
    discard await client.getContent(URL_TOKEN_API & "?command=reset&token=" & token)

when isMainModule:
  echo(URL_API)
  let client = newHttpClient()
  echo client.size(Category.TV)
  let token = client.createToken()
  echo token
  client.resetToken(token)
  echo client.getQuestions(category=TV)
  echo client.totalSize()
  close client

export httpclient
