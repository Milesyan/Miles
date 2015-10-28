//
//  MedSearchController.h
//  emma
//
//  Created by Eric Xu on 12/31/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MedicineViewController.h"

@interface MedSearchController : UIViewController <UISearchBarDelegate, UISearchDisplayDelegate>

@property (nonatomic, strong) IBOutlet MedicineViewController *searchResultDelegate;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;


@end
