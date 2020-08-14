this is a simple wrapper around [The Open Trivia Database](https://opentdb.com) which is a api to get trivia questions from a variety of categories and in multiple choice or true/false fashion

The library is both sync and async

### Example

```nim
import opentrivadb
import httpclient

let client = newHttpClient()
echo client.getQuestions() # Gets 10 questions and prints them out

let asyncClient = newAsyncHttpClient()
waitFor client.getQuestions()
```

make sure to enable ssl when running
