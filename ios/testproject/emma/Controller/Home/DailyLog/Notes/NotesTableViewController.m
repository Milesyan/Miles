//
//  NotesTableViewController.m
//  emma
//
//  Created by Xin Zhao on 7/14/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "NotesTableViewController.h"
#import "NotesManager.h"
#import "NotesItemCell.h"
#import "UIView+FindAndResignFirstResponder.h"

#define CELL_ID_NOTES_ROW @"NotesItem"
#define CELL_ID_NOTES_LAST_ROW @"NotesLastItem"

@interface NotesTableViewController () <NotesItemCellDelegate> {
    NSMutableArray *notes;
    NSString *newlyAdded;
    NSInteger editingRow;
}

@property (weak, nonatomic) IBOutlet UIView *whiteCover;

@end

@implementation NotesTableViewController

- (NoteAddItemCell *)lastCell {
    return (NoteAddItemCell *)[self.tableView
        cellForRowAtIndexPath:[NSIndexPath indexPathForRow:
        [notes count] inSection:0]];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"NotesItemCell"
        bundle:nil] forCellReuseIdentifier:CELL_ID_NOTES_ROW];
    [self.tableView registerNib:[UINib nibWithNibName:@"NoteAddItemCell"
        bundle:nil] forCellReuseIdentifier:CELL_ID_NOTES_LAST_ROW];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    notes = [[NotesManager getNotesForDate:self.dateString] mutableCopy];
    newlyAdded = @"";
    editingRow = -1;
    
    self.navigationItem.hidesBackButton = YES;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
//    UIView *coverView = [self]
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardDidHideNotification object:nil];
    [self subscribe:EVENT_NOTE_EDIT_SCROLL_PAGE selector:@selector(dailyNotesEditing:)];
    
    if (!notes || notes.count == 0) {
        [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self  name:UIKeyboardDidHideNotification object:nil];
    [self unsubscribeAll];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [notes count] + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < [notes count]) {
        CGFloat h = [NotesItemCell rowHeightForNote:notes[indexPath.row]];
        return h;
    }
    CGFloat h = [NotesItemCell rowHeightForNote:newlyAdded];
    return h;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NoteAddItemCell *cell = nil;
    if (indexPath.row < [notes count]) {
        cell = [tableView dequeueReusableCellWithIdentifier:
            CELL_ID_NOTES_ROW forIndexPath:indexPath];
        [cell setNote:notes[indexPath.row]];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:
            CELL_ID_NOTES_LAST_ROW forIndexPath:indexPath];
        [((NoteAddItemCell*)cell) setup];
    }
    cell.noteIndex = indexPath.row;
    cell.delegate = self;
    cell.editing = NO;
    return cell;
    
    // Configure the cell...
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingRow >= 0) {
        [self.tableView findAndResignFirstResponder];
    }
    else {
        if (indexPath.row == [notes count]) {
            NoteAddItemCell *cell = (NoteAddItemCell *)[tableView
                cellForRowAtIndexPath:indexPath];
            [cell tableCellSelected];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < [notes count] && indexPath.row != editingRow) {
        return YES;
    } else {
        return NO;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)TableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < [notes count]) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < [notes count] && indexPath.row != editingRow) {
        [self.tableView findAndResignFirstResponder];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self commitSave];
        [self reloadTable];
        [notes removeObjectAtIndex:indexPath.row];
        [self commitSave];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadData];
    }
//    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:
    (UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:indexPath.row % 2 ? UIColorFromRGB(0xF6F5EF)
        : UIColorFromRGB(0xFBFAF7)];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.tableView findAndResignFirstResponder];
}

#pragma mark - NotesItemCell delegate
- (void)updateNoteContentAtIndex:(NSInteger)index withNote:
    (NSString *)note
{
    if (index < [notes count]) {
        notes[index] = note;
    }
    else if (index == [notes count]) {
        newlyAdded = note;
    }
}

- (void)beginEditingRow:(NSInteger)index {
    editingRow = index;
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)saveButtonClicked:(id)sender {
    [self.tableView findAndResignFirstResponder];
    [self commitSave];
    [self.navigationController popViewControllerAnimated:YES from:self];
}

- (void)keyboardWillHide:(NSNotification *)sysNotification
{
    [self commitSave];
    [self reloadTable];
//    [Utils performInMainQueueAfter:0.5f callback:^{
//        [self reloadTable];
//    }];
}

# pragma mark - data processing
- (void)commitSave {
    editingRow = -1;
    newlyAdded = [newlyAdded stringByTrimmingCharactersInSet:[NSCharacterSet
        whitespaceAndNewlineCharacterSet]];
    if (![newlyAdded isEqualToString:@""]) {
        [notes addObject:newlyAdded];
        newlyAdded = @"";
    }
    [NotesManager saveNotes:notes forDate:self.dateString];
}

- (void)reloadTable {
    notes = [[NotesManager getNotesForDate:self.dateString] mutableCopy];
    newlyAdded = @"";
    [self.tableView reloadData];
}

# pragma mark - events handler
- (void)dailyNotesEditing:(Event *)event {
    // dynamic change the row height
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

@end
