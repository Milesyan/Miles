//
//  NotesItemCell.m
//  emma
//
//  Created by Jirong Wang on 10/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "NotesItemCell.h"
#import "NotesManager.h"
#import "User.h"

#define TEXT_WIDTH SCREEN_WIDTH - 40

@interface NotesItemCell() <UITextViewDelegate> {
}

@property (nonatomic) NSDate * currentDate;
@property (nonatomic) CGFloat currentHeight;

@end

@implementation NotesItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    self.noteTextView.delegate = self;
    [self.noteTextView setFont:[UIFont fontWithName:@"ProximaNova-Regular" size:18.0]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (CGFloat)textViewHeight:(NSString *)text {
    NSString * temp = text;
    if ([Utils isEmptyString:text]) {
        temp = @"t";
    }
    UITextView * calculateView = [[UITextView alloc] init];
    [calculateView setText:temp];
    [calculateView setFont:[UIFont fontWithName:@"ProximaNova-Regular" size:18.0]];
    [calculateView setFrame:CGRectMake(0, 0, TEXT_WIDTH, FLT_MAX)];
    [calculateView setScrollEnabled:YES];
    [calculateView sizeToFit];
    [calculateView setScrollEnabled:NO];
    CGSize size = calculateView.frame.size;
    return size.height >= 30 ? size.height : 30;
}

+ (CGFloat)rowHeightForDate:(NSString *)dateLabel atIndex:(NSInteger)index {
    NSString * text = [NotesManager getNoteForDate:dateLabel atIndex:index];
    return [self textViewHeight:text] + NOTE_ROW_HEIGHT_OFFSET;
}

+ (CGFloat)rowHeightForNote:(NSString *)noteContent {
    return [self textViewHeight:noteContent] + NOTE_ROW_HEIGHT_OFFSET;
}

- (void)setModelForDate:(NSDate *)date atIndex:(NSInteger)index {
    NSString * str = [NotesManager getNoteForDate:date2Label(date) atIndex:index];
    if ((str) && (![Utils isEmptyString:str])){
        self.noteTextView.text = str;
    } else {
        self.noteTextView.text = @"";
    }
    self.currentDate = date;
    self.noteIndex = index;
    [self resizeTextView:self.noteTextView];
}

- (void)setNote:(NSString *)noteContent {
    if ((noteContent) && (![Utils isEmptyString:noteContent])){
        self.noteTextView.text = noteContent;
    } else {
        self.noteTextView.text = @"";
    }
//    self.currentDate = date;
//    self.noteIndex = index;
    [self resizeTextView:self.noteTextView];
}

- (void)resizeTextView:(UITextView *)textView {
    /*
     * In IOS6 and 7, the "sizeToFit" function does not work fine
     * for textView(limited height in cell) and calculateView
     */
    textView.frame = setRectWidth(textView.frame, TEXT_WIDTH);
    [textView setScrollEnabled:YES];
    [textView sizeToFit];
    [textView setScrollEnabled:NO];
    textView.frame = setRectWidth(textView.frame, TEXT_WIDTH);
    self.currentHeight = textView.frame.size.height;
}

#pragma mark - UITextView delegate
- (void)textViewDidChange:(UITextView *)textView {
    CGFloat h = [NotesItemCell textViewHeight:textView.text];
    if (h != self.currentHeight) {
        CGFloat diff = h - self.currentHeight;
        [self resizeTextView:textView];
        [self.delegate updateNoteContentAtIndex:self.noteIndex withNote:
            self.noteTextView.text];
        /* There is a crash case -
         *   if user selected all and delete the text, in this case, if we delete the
         *   text in data source, we will have inconsistent between table cells and 
         *   table data source (we do "table beginUpdates")
         * To avoid this crash case, we save an empty note
         */
//        if ([Utils isEmptyString:textView.text]) {
//            [self saveEmptyNote];
//        } else {
//            [self saveNote:textView.text];
//        }
        [self publish:EVENT_NOTE_EDIT_SCROLL_PAGE data:@(diff)];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\n"]){
        [textView resignFirstResponder];
        return NO;
    }else{
        return YES;
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
//    if ([NotesManager canEdit:self.noteIndex]) {
//        [NotesManager startEdit:self.noteIndex];
//        return YES;
//    } else {
//        return NO;
//    }
    if ([self isEditing]) {
        return NO;
    }
    [self.delegate beginEditingRow:self.noteIndex];
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if ([textView.text length] > 1000) {
        UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Message is too long."
                                                       message:@"Sorry, a note can not be longer than 1000 characters."
                                                      delegate:self
                                             cancelButtonTitle:@"ok"
                                             otherButtonTitles:nil];
        [alert show];
        return NO;
    } else {
        return YES;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [textView resignFirstResponder];
    [self.delegate updateNoteContentAtIndex:self.noteIndex withNote:
        self.noteTextView.text];
//    [self saveNote:textView.text];
//    [NotesManager endEdit];
//    [self publish:EVENT_DAILY_NOTES_UPDATED];
//    [self publish:EVENT_DAILY_DATA_DIRTIED];
}

- (void)saveNote:(NSString *)text {
//    if ([Utils isEmptyString:text]) {
//        [NotesManager removeNoteForDate:date2Label(self.currentDate) atIndex:self.noteIndex];
//    } else {
//        [NotesManager tsetNote:text forDate:date2Label(self.currentDate) atIndex:self.noteIndex];
//    }
}

- (void)saveEmptyNote {
//    [NotesManager tsetNote:@"" forDate:date2Label(self.currentDate) atIndex:self.noteIndex];
}

/*
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
*/
@end


@interface NoteAddItemCell() {
}

@property (nonatomic) IBOutlet UIView * addNoteView;

@end

@implementation NoteAddItemCell

- (void)setup {
    self.noteTextView.text = @"";
    self.noteTextView.hidden = YES;
    self.addNoteView.hidden = NO;
}

- (void)setModelForDate:(NSDate *)date atIndex:(NSInteger)index {
    [super setModelForDate:date atIndex:index];
    self.noteTextView.text = @"";
    self.noteTextView.hidden = YES;
    self.addNoteView.hidden = NO;
}

- (void)tableCellSelected {
    self.noteTextView.hidden = NO;
    self.addNoteView.hidden = YES;
    /* There is a crash case -
     *   until user inputs more than 1 lines of notes, the last notes is not saved
     *   in table data source.  Therefore, any animation / rows count during this 
     *   time will get wrong rows and get crash (e.g. select daily Todo)
     * To avoid this crash case, we save an empty note
     */
//    [self saveEmptyNote];
    [self.noteTextView becomeFirstResponder];
    [self.delegate updateNoteContentAtIndex:self.noteIndex withNote:
        self.noteTextView.text];
}

@end
