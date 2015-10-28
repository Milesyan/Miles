//
//  NotesEntranceCell.h
//  emma
//
//  Created by Xin Zhao on 7/13/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NotesCellDelegate <NSObject>
- (void)tableViewCell:(UITableViewCell *)cell needsPerformSegue:(NSString *)segueIdentifier;
@end
@interface NotesEntranceCell : UITableViewCell
@property (nonatomic, weak) id<NotesCellDelegate> delegate;
- (void)setNotesPreview:(NSString *)notesContent;

@end
