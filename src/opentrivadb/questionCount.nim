type 
    QuestionCount* = object
        total_question_count*: int
        total_easy_question_count*: int
        total_medium_question_count*: int
        total_hard_question_count*: int

    GlobalCount* = object
        total_num_of_questions*: int
        total_num_of_pending_questions*: int
        total_num_of_verified_questions*: int
        total_num_of_rejected_questions*: int    
