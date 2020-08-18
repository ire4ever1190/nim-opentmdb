import httpclient
import asyncdispatch
import json
import uri
import opentdb/constants

include opentdb/question
include opentdb/categories
include opentdb/questionType
include opentdb/questionCount

proc encodeQuery(values: openArray[(string, string)]): string =
    result = "?"
    for (key, value) in values:
        if value == "":
            continue
        result &= "&" & key & "=" & value

## This package is a wrapper around [opentdb](https://opentdb.com)
## It is both async and sync so that is why there is two procs for each

proc getQuestions*(client: HttpClient|AsyncHttpClient, category: Category = Any, difficulty: string = "any", questionType: QuestionType = Both, amount: int = 10, token: string = ""): Future[seq[Question]] {.multisync.} =
    ## Gets questions from https://opentdb.com in either sync or async fashion
    ## questions are encoded in url3986 (can be decoded with decodeUrl in uri module)
    ## Different categories that can be selected can be found in categories.nim
    ## difficulty is either "any", easy", "medium", or "hard"
    ## boolean means the answer is either true or false
    ## num is how many questions you want
    runnableExamples:
        import httpclient
        let client = newHttpClient()
        # Get questions with default parameters
        let questions = client.getQuestions()
        # Get questions that are easy
        let easyQuestions = client.getQuestions(difficulty="easy")
        # Get questions in relation to TV
        let tvQuestions = client.getQuestions(category=TV)
        # Get 100 questions
        let hundredQuestions = client.getQuestions(amount=100)
        # You can also combine them
        let combinationQuestions = client.getQuestions(difficulty="easy", category=TV, amount=100)
    
    when not defined(danger): # if you have turned on danger then you probably dont want this slowing you down
        if not ["any", "easy", "medium", "hard"].contains(difficulty):
            raise ValueError.newException("Difficulty parameter is not one of 'any', 'easy', 'medium', or 'hard'")

        if amount <= 0:
            raise ValueError.newException("'num' parameter must be > 0")

    let questionTypeValue = case questionType:
        of Both:
            ""
        of MultipleChoice:
            "multiple"
        of Boolean:
            "Boolean"
            
    let queryString = encodeQuery({
        "amount": $amount,
        "difficulty": if difficulty == "any": "" else: difficulty,
        "category": if category == Any: "" else: $ord(category),
        "encode": "url3986"
    })
    let url = URL_API & queryString
    #TODO decode body here
    let body = await client.getContent(url)
    let jsonBody = parseJson(body)

    case jsonBody["response_code"].getInt():
    of 1:
        raise IOError.newException("No Results: This could be because you were asking for too many questions")
    of 2:
        raise ValueError.newException("Invalid Parameter: Please make a bug report for this and show this in the issue " & queryString)
    of 3:
        raise ValueError.newException("Token Not Found: You probably have not created the token, please use the createToken proc to get one")
    of 4:
        raise ValueError.newException("Token Empty: You have gotten all the possible questions and so you need to reset the token")
    else: # response_code == 0
        return jsonBody["results"].to(seq[Question])
                

proc size*(client: HttpClient|AsyncHttpClient, category: Category): Future[QuestionCount] {.multisync.} =
    ## Returns the numbers of questions in a category
    runnableExamples:
        import httpclient
        let client = newHttpClient()
        echo(client.size(TV).totalQuestionCount)
    if category == Any:
        raise ValueError.newException("Category cannot be Any, please use totalSize to get that")
    let url = URL_COUNT & $ord(category)
    let response = await client.getContent(url)
    return parseJson(response)["category_question_count"].to(QuestionCount)

proc totalSize*(client: HttpClient|AsyncHttpClient): Future[GlobalCount] {.multisync.} =
    ## Returns the number of questions in total that opentdb has
    runnableExamples:
        import httpclient
        let client = newHttpClient()
        echo(client.totalSize().totalNumOfQuestions)
    let url = URL_COUNT_GLOBAL
    let response = await client.getContent(url)
    return parseJson(response)["overall"].to(GlobalCount)

proc createToken*(client: HttpClient|AsyncHttpClient): Future[string] {.multisync.} =
    ## Creates a token which makes sure you do not get the same questions twice
    ## After a while you will run out of responses and will need to reset the token
    runnableExamples:
        import httpclient
        let client = newHttpClient()
        let token = client.createToken()
        let questions = client.getQuestions(token=token)
        let secondQuestions = client.getQuestions(token=token)
        # secondQuestions will not have any questions that are in questions
    let url = URL_TOKEN_API & "?command=request"
    let response = await client.getContent(url)
    return parseJson(response)["token"].getStr()

proc resetToken*(client: HttpClient|AsyncHttpClient, token: string) {.multisync.} =
    ## Resets a token so it can reuse questions
    # discard await is used so that it makes sure the token is reset before returning to the user
    runnableExamples:
        import httpclient
        let client = newHttpClient()
        let token = client.createToken()
        # Run code that uses up all the questions
        client.resetToken(token)
        # Now you can rerun the code before
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
