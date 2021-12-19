this is a simple wrapper around [The Open Trivia Database](https://opentdb.com) which is a api to get trivia questions from a variety of categories and in multiple choice or true/false fashion

The library is both sync and async
install through nimble (I know it is spelled wrong)

[Docs available here](https://tempdocs.netlify.app/opentdb/stable/opentdb.html)

```
nimble install opentdb
```

### Example

```nim
import opentrivadb
import httpclient

let client = newHttpClient()
echo client.getQuestions() # Gets 10 questions and prints them out

let asyncClient = newAsyncHttpClient()
let questions = waitFor client.getQuestions()
for question in questions:
  echo question.question
```

make sure to enable ssl when running
