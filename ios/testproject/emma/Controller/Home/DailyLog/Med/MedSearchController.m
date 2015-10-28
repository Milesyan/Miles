//
//  MedSearchController.m
//  emma
//
//  Created by Eric Xu on 12/31/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "MedSearchController.h"
#import "MedManager.h"

#pragma mark - Class MedicineSearchController
@interface MedicineSearchController : UISearchDisplayController

@end

@implementation MedicineSearchController

- (void)awakeFromNib {
    [self.searchContentsController.view setBackgroundColor:UIColorFromRGB(0xF7F6F0)];
}

- (void)setActive:(BOOL)visible animated:(BOOL)animated
{
    [super setActive: visible animated: animated];
    [self.searchContentsController.navigationController setNavigationBarHidden:NO animated: NO];
}
@end


#pragma mark - Class MedicineSearchBar
@interface MedicineSearchBar : UISearchBar

@end

@implementation MedicineSearchBar

- (void)awakeFromNib {
    
}

- (void)layoutSubviews{
    [super layoutSubviews];
    [self setShowsCancelButton:NO animated:NO];
}
@end


#pragma mark - Class MedSearchController
@interface MedSearchController() {
    NSArray *dataSourceArray;
    NSString *userSearchText;
    NSAttributedString *createMedAttrStr;
}

@end

@implementation MedSearchController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.searchDisplayController.searchResultsTableView setBackgroundColor:UIColorFromRGB(0xF7F6F0)];
    [self.searchDisplayController.searchResultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    dataSourceArray = [MedManager medList];
    userSearchText = @"";
    createMedAttrStr = [[NSAttributedString alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:0.3
                     animations:nil
                     completion:^(BOOL finished) {
                         [self.searchBar becomeFirstResponder];
                         if (self.searchBar.text) {
                             self.searchBar.text = self.searchBar.text;
                             [self searchBar:self.searchBar textDidChange:self.searchBar.text];
                         }
                     }];
}


#pragma mark - UISearchBarDelegate, UISearchDisplayDelegate
-(NSMutableArray *)searchByContains:(NSString *)containsString inputArray:(NSMutableArray *)inputArray
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", [Utils trim:containsString]];
    NSMutableArray *mArrayFiltered = [[inputArray filteredArrayUsingPredicate:predicate] mutableCopy];
    return mArrayFiltered;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    userSearchText = searchText;
    dataSourceArray = [self searchByContains:userSearchText inputArray:[NSMutableArray arrayWithArray:[MedManager medList]]];
    createMedAttrStr = [Utils markdownToAttributedText:[NSString stringWithFormat: @"Create “**%@**” as a new entry", userSearchText] fontSize:18 lineHeight:18 color:UIColorFromRGB(0x5C66D0)];
    
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    // A hack to fix the black background color issue
    NSArray *subviews = searchBar.subviews;
    if (subviews.count > 0) {
        subviews = [subviews[0] subviews];
    }
    for (UIView *each in subviews) {
        if ([each isKindOfClass:NSClassFromString(@"UISearchBarBackground")]) {
            each.backgroundColor = [UIColor whiteColor];
            each.alpha = 0;
            each.hidden = YES;
            break;
        }
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    searchBar.hidden = YES;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1 + ([dataSourceArray count] > 0? 1: 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([dataSourceArray count] > 0 && section == 0) {
        return [dataSourceArray count];
    } else return 1;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.searchResultDelegate) {
        NSString *medName;
        if (indexPath.section == 0 && [dataSourceArray count] > 0) {
            medName = dataSourceArray[indexPath.row];
        } else {
            medName = userSearchText;
        }

        [self.searchResultDelegate setMedicineNameFromSearch:medName];
        [self.searchDisplayController setActive:NO animated:YES];
    }
}

- (CGFloat)tableView:tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([dataSourceArray count] > 0 && indexPath.section == 0) {
        return 60;
    } else {
        return [UILabel sizeForText:createMedAttrStr inBound:CGSizeMake(SCREEN_WIDTH, CGFLOAT_MAX)].height + 30;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        [cell setBackgroundColor:UIColorFromRGB(0xF7F6F0)];
        [cell.textLabel setNumberOfLines:0];
        [cell.textLabel setLineBreakMode:NSLineBreakByWordWrapping];
    }
    
    if ([dataSourceArray count] > 0 && indexPath.section == 0) {
        [cell.textLabel setText:dataSourceArray[indexPath.row]];
    } else {
        [cell.textLabel setAttributedText:createMedAttrStr];
    }
    // Configure the cell...
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 44)];
    [header setBackgroundColor:UIColorFromRGB(0xDADCE0)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, SCREEN_WIDTH-20, 20)];
    [label setFont:[Utils defaultFont:14]];
    [header addSubview:label];
    if (section == 0) {
        [label setText:@"Choose a match below"];
    } else {
        [label setText:@"Can’t find a match? Create a new entry!"];
    }
    [label setBackgroundColor:[UIColor clearColor]];
    [label sizeToFit];
    return header;
}


-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.searchBar.hidden = NO;
}

@end
