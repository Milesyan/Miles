# Usage
Create some questions by:
```objective-c
GLYesOrNoQuestion *question = [GLYesOrNoQuestion new];
question.key = @"q1";
question.title = @"Question 1";
```

Set them as the quesiton view's model and then reload it:
```objective-c
self.questionListView.questions = @[question1, question2, question3];
[self.questionListView reloadData]
```

# Question Type
All the question has following properties:

* title: the question title
* answer: the answer
* key: you can specify a key to it
* subQuestions: subquestions belong to it
* subQuestionsSeparatorTitle: the separator title for sub questions sections
* answerToShowSubQuestions: when the answer match this value, the subquestions will get shown

 

#### GLYesOrNoQuestion
```objective-c
GLYesOrNoQuestion *question = [GLYesOrNoQuestion new];
question.key = @"q1";
question.title = @"Question 1";
question.answerToShowSubQuestions = ANSWER_YES;
```

#### GLPickerQuestion
```objective-c
GLPickerQuestion *question = [GLPickerQuestion new];
question.title = @"Question 2";
question.optionTitles = @[@"option 1", @"option 2"];
question.optionValues = @[@"1", @"2"];
```

#### GLNumberQuestion
```objective-c
GLNumberQuestion *question = [GLNumberQuestion new];
question.title = @"Question 3";
question.padType = DECIMAL_PAD; // or NUMBER_PAD
question.unitList = @[[GLUnit unitWithName:@"kg" weight:1], [GLUnit unitWithName:@"lb" weight:2]];
```

#### GLDateQuestion
```objective-c
GLDateQuestion *question = [GLDateQuestion new];
question.title = @"Question 4";
question.pickerMode = MODE_TIME; // MODE_DATE, MODE_DATE_AND_TIME
question.answer = @"15928347234" // the answer is a timestamp
```
# Support other question types
For example, we need to build a cell to support answering question with a picker, there two steps:

First we need to create a GLQuestion subclass:
```objective-c
@interface GLPickerQuestion : GLQuestion
@property (nonatomic, copy) NSString *pickerTitle;
@property (nonatomic, strong) NSArray *optionTitles;
@property (nonatomic, strong) NSArray *optionValues;
@end
```

Then create the actual question cell, its name must match the corresponding question class name:
```objective-c
@interface GLPickerQuestionCell : GLQuestionBaseCell
@property (nonatomic, strong) GLPickerQuestion *question;
@end
```


When the answer is changed, you should call `[self updateAnwser:value]` to notify the changes;

```objective-c
@interface GLPickerQuestionCell()
@property (weak, nonatomic) IBOutlet GLPillButton *button;
@property (weak, nonatomic) IBOutlet UILabel *questionLabel;
@end

@implementation GLPickerQuestionCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setQuestion:(GLPickerQuestion *)question
{
    [super setQuestion:question];
    self.questionLabel.text = question.title;
    if (question.answer) {
        [self.button setTitle:question.answer forState:UIControlStateNormal];
    } else {
        [self.button setTitle:@"Choose" forState:UIControlStateNormal];
    }
}

- (IBAction)buttonPressed:(id)sender
{
    int selectedRow = (int)[self.question.optionValues indexOfObject:self.question.answer];
    [GLGeneralPicker presentSimplePickerWithTitle:self.question.pickerTitle rows:self.question.optionTitles selectedRow:selectedRow showCancel:YES withAnimation:YES doneCompletion:^(NSInteger row, NSInteger comp) {
        NSString *value = self.question.optionValues[row];
        [self updateAnwser:value];
        [self.button setTitle:value forState:UIControlStateNormal];
    } cancelCompletion:^(NSInteger row, NSInteger comp) {
        
    }];
}
@end
```

Finally, register this question to the registry:
```objective-c
[[GLQuestionRegistry sharedInstance]] registerQuestion:[GLPickerQuestion class]];
```


