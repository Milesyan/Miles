//
//  TipsDialog.m
//  emma
//
//  Created by Xin Zhao on 13-10-18.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "TipsDialog.h"

@interface StarredRowCell()

@property (weak, nonatomic) IBOutlet UILabel *updateInfoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *infoCellStar;

@end

@implementation StarredRowCell

- (void)awakeFromNib {
    [self.infoCellStar setImage:[Utils imageNamed:@"star" withColor:UIColorFromRGB(0xffc000)]];
    self.infoCellStar.backgroundColor = [UIColor clearColor];
}

- (void)setTweak:(NSDictionary*)tweak {
    if (tweak[@"STAR_HIDE"]) {
        self.infoCellStar.hidden = YES;
    }
    if (tweak[@"STAR_LEFT"]) {
        self.infoCellStar.frame = setRectX(self.infoCellStar.frame, [tweak[@"STAR_LEFT"] floatValue]);
    }
}

- (void)setLabelText:(NSString *)text {
    NSAttributedString *markdownText = [Utils markdownToAttributedText:text fontSize:15 color:[UIColor blackColor]];
//    self.updateInfoLabel.text = text;
    self.updateInfoLabel.attributedText = markdownText;
    [self.updateInfoLabel setFrame:setRectHeight(self.updateInfoLabel.frame, [StarredRowCell getTextHeight:text])];
}

+ (CGFloat)getTextHeight:(NSString *)text {
    CGSize size = [text boundingRectWithSize:CGSizeMake(205, 1000)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{NSFontAttributeName:[Utils lightFont:15.0]}
                                     context:nil].size;
    return roundf(size.height) + 16;
}

@end

@interface TipsDialog () {
    NSArray * rowsText;
    NSArray * displayTweaks;
}
@property (weak, nonatomic) IBOutlet UITableView *infoTableView;
@end

@implementation TipsDialog

static TipsDialog *_tipsDlg = nil;
+ (TipsDialog *)getInstance {
    if (!_tipsDlg) {
        _tipsDlg = [[TipsDialog alloc] init];
    }
    return _tipsDlg;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setTweaks:(NSArray *)tweaks rows:(NSArray *)rows {
    rowsText = [NSArray arrayWithArray:rows];
    displayTweaks = [NSArray arrayWithArray:tweaks];
    [self.infoTableView reloadData];
}

- (void)viewDidLoad
{
//    [super viewDidLoad];
    [self.infoTableView registerNib:[UINib nibWithNibName:@"StarredRowCell" bundle:nil] forCellReuseIdentifier:@"StarredRowCell"];
    
 
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return rowsText.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    StarredRowCell *cell = [self.infoTableView dequeueReusableCellWithIdentifier:@"StarredRowCell"];
    [cell setLabelText:[rowsText objectAtIndex:indexPath.row]];
    [cell setTweak:displayTweaks[indexPath.row]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [StarredRowCell getTextHeight:[rowsText objectAtIndex:indexPath.row]];
}
@end
