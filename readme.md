This is a simple sync/async wrapper around [The Open Trivia Database](https://opentdb.com) which is an api to get trivia questions from a variety of categories in multiple choice or true/false fashion


[Docs available here](https://tempdocs.netlify.app/opentdb/stable/opentdb.html)

install through nimble 
```
nimble install opentdb
```

### Example

```nim
import opentrivadb

let client = newHttpClient()
echo client.getQuestions() # Gets 10 questions and prints them out

let asyncClient = newAsyncHttpClient()
let questions = waitFor client.getQuestions()
for question in questions:
  echo question.question
```

make sure to enable ssl when running
