//
//  GeniusMainViewController.h
//  emma
//
//  Created by Ryan Ye on 7/24/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GeniusChildViewController.h"

#define TOPLEFT @"topleft"
#define TOPRIGHT @"topright"
#define MIDDLE @"middle"
#define BOTTOMLEFT @"bottomleft"
#define BOTTOMRIGHT @"bottomright"

#define TAG_GENIUS_CHILD_INSIGHT         1
#define TAG_GENIUS_CHILD_BBT_CHART       4
#define TAG_GENIUS_CHILD_MY_CYCLES       6
#define TAG_GENIUS_CHILD_WEIGHT_CHART    7
#define TAG_GENIUS_CHILD_CALORIES_CHART  8
#define TAG_GENIUS_CHILD_NUTRITION_CHART 9

#define GENIUSMAIN_REFERRAL_H 112

//----------------------------------------------------
//        5      BLOCK       5       BLOCK     5
// = 2.5 + 2.5 + BLOCK + 2.5 + 2.5 + BLOCK + 2.5 + 2.5
// = 2.5 + (BLOCK_w_padding) + (BLOCK_w_padding) + 2.5
//
// So, SCREEN_WITH = (BLOCK_w_padding + 2.5)*2
//
#define GENIUSMAIN_BLOCK_PADDING 2.5f
#define GENIUSMAIN_BLOCK_WIDTH  ((SCREEN_WIDTH/2.0) - GENIUSMAIN_BLOCK_PADDING)
#define GENIUSMAIN_BLOCK_HEIGHT (IS_IPHONE_4 ? GENIUSMAIN_BLOCK_WIDTH : GENIUSMAIN_BLOCK_WIDTH)
#define GENIUSMAIN_BLOCK_LEFT_X      GENIUSMAIN_BLOCK_PADDING
#define GENIUSMAIN_BLOCK_RIGHT_X     (GENIUSMAIN_BLOCK_PADDING + GENIUSMAIN_BLOCK_WIDTH)

#define GENIUSMAIN_BLOCK_CORNER_RADIUS 5
#define GENIUSMAIN_BLOCK_TRUE_WIDTH  (GENIUSMAIN_BLOCK_WIDTH - GENIUSMAIN_BLOCK_PADDING*2)
#define GENIUSMAIN_BLOCK_TRUE_HEIGHT (GENIUSMAIN_BLOCK_HEIGHT - GENIUSMAIN_BLOCK_PADDING*2)

#define GENIUS_SINGLE_BLOCK_TITLE_WIDTH (GENIUSMAIN_BLOCK_TRUE_WIDTH - 10*2)
#define GENIUS_DOUBLE_BLOCK_TITLE_WIDTH ((GENIUSMAIN_BLOCK_WIDTH * 2 - GENIUSMAIN_BLOCK_PADDING*2) - 10*2)

#define GG_FULL_CONTENT_W (SCREEN_WIDTH - 40)

@interface GeniusMainViewController : UIViewController

@property (nonatomic) BOOL animationLocked;
@property (nonatomic, strong) UIImage *presentingViewSnapshot;
@property (nonatomic, strong) NSNumber *unreadViewTag;
@property IBOutlet UIScrollView *containerScrollView;

- (CGRect)viewFrameOfChild:(UIViewController *)childViewController;
- (void)refreshChildrenLayout;
- (UIView *)getChildContainerView:(NSInteger)childTag;
- (UIView *)getBlockAnimationView;
- (void)goReferral;
- (GeniusChildViewController *)getGeniucChildController:(NSInteger)childTag;
- (void)tutorialDidComplete;
- (BOOL)anyChildOpened;
@end
