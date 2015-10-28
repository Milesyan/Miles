//
//  NotesItemCell.h
//  emma
//
//  Created by Jirong Wang on 10/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define NOTE_ROW_HEIGHT_OFFSET 38

@protocol NotesItemCellDelegate <NSObject>

@required
- (void)updateNoteContentAtIndex:(NSInteger)index withNote:
    (NSString *)note;
- (void)beginEditingRow:(NSInteger)index;

@end


@interface NotesItemCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UITextView *noteTextView;
@property (nonatomic) NSInteger noteIndex;
@property (nonatomic) id<NotesItemCellDelegate> delegate;

+ (CGFloat)rowHeightForDate:(NSString *)dateLabel atIndex:(NSInteger)index;
+ (CGFloat)rowHeightForNote:(NSString *)noteContent;
- (void)setModelForDate:(NSDate *)date atIndex:(NSInteger)index;
- (void)setNote:(NSString *)noteContent;

@end

@interface NoteAddItemCell : NotesItemCell

- (void)tableCellSelected;
- (void)setup;

@end
