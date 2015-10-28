//
//  AllClinicsTableViewController.m
//  emma
//
//  Created by Xin Zhao on 13-4-5.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "AllClinicsTableViewController.h"
#import "User.h"
#import "Logging.h"
#import "ClinicsManager.h"
#import <MapKit/MapKit.h>

#define MILES_PER_METER 0.000621371192
#define DRIVING_THRESHOLD 200

@interface AllClinicsTableViewController () <CLLocationManagerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSMutableDictionary *clinicsInStates;
@property (strong, nonatomic) NSMutableArray *allStates;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation AllClinicsTableViewController

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
    
    self.locationManager = [[CLLocationManager alloc] init];
    GLLog( @"Starting CLLocationManager" );
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = 200;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    if (IOS8_OR_ABOVE) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    [self.locationManager startUpdatingLocation];
    

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // logging
    [Logging log:PAGE_IMP_HELP_CLINICS_ALL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (NSMutableDictionary *)clinicsInStates {
    if (!_clinicsInStates) {
        [self loadClinicsData];
    }
    return _clinicsInStates;
}

- (NSMutableArray *)allStates {
    if (!_allStates) {
        [self loadClinicsData];
    }
    return _allStates;
}

- (void)loadClinicsData {
    _clinicsInStates = [NSMutableDictionary dictionary];
    _allStates = [NSMutableArray array];
    
    NSSortDescriptor *recommendSortDesc = [NSSortDescriptor sortDescriptorWithKey:@"recommend" ascending:NO];
    
    // create a pointer to a dictionary
    NSDictionary *dictionary;
    
    dictionary = [ClinicsManager readClinics];
    for (id state in dictionary) {
        [_allStates addObject:state];
        
        NSArray *clinicsInState = [dictionary objectForKey:state];
        NSMutableArray *convertedClinisInState = [NSMutableArray arrayWithCapacity:[clinicsInState count]];
        for (int idx = 0; idx < [clinicsInState count]; idx++) {
            NSDictionary *clinic = [clinicsInState objectAtIndex:idx];
            NSMutableDictionary *convertedClinic = [NSMutableDictionary dictionaryWithDictionary:@{
                                                    @"name": [clinic objectForKey:@"name"],
                                                    @"address": [clinic objectForKey:@"address"]}];
            int recommend = 0;
            if ([clinic objectForKey:@"recommend"]) {
                recommend = [[clinic objectForKey:@"recommend"] intValue];
            }
            [convertedClinic setObject:@(recommend) forKey:@"recommend"];
            
            if ([clinic objectForKey:@"lat"]) {
                double lat = [[clinic objectForKey:@"lat"] doubleValue];
                double lng = [[clinic objectForKey:@"lng"] doubleValue];
                [convertedClinic setObject:[NSNumber numberWithDouble:lat] forKey:@"lat"];
                [convertedClinic setObject:[NSNumber numberWithDouble:lng] forKey:@"lng"];
                if ([User currentUser].currentLocation) {
                    CLLocationDistance distance = [[User currentUser].currentLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:lat longitude:lng]] * MILES_PER_METER;
                    [convertedClinic setObject:[NSNumber numberWithDouble:distance] forKey:@"distance"];
                }
            }
            [convertedClinisInState addObject:convertedClinic];
        }
        [convertedClinisInState sortUsingDescriptors:@[recommendSortDesc]];
        
        [_clinicsInStates setObject:convertedClinisInState forKey:state];
    }
    [_allStates sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.clinicsInStates count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{    // Return the number of rows in the section.
    return [[self.clinicsInStates objectForKey:[self.allStates objectAtIndex:section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *clinicInfo = [[self.clinicsInStates objectForKey:[self.allStates objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    BOOL isRecommend = [[clinicInfo objectForKey:@"recommend"] intValue] > 0;
    NSString * cellIdentifier = isRecommend ? CLINIC_TABLE_RECOMMEND_IDENTIFIER : CLINIC_TABLE_CELL_IDENTIFIER;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }

    UILabel *label = (UILabel *)[cell viewWithTag:100];
    [label setAdjustsFontSizeToFitWidth:NO];
    [label setLineBreakMode:NSLineBreakByTruncatingTail];
    [label setText:[clinicInfo objectForKey:@"name"]];
    label = (UILabel *)[cell viewWithTag:200];
    [label setAdjustsFontSizeToFitWidth:NO];
    [label setLineBreakMode:NSLineBreakByTruncatingTail];
    [label setText:[clinicInfo objectForKey:@"address"]];
    label = (UILabel *)[cell viewWithTag:300];
    [label setText: [clinicInfo objectForKey:@"distance"] ? [NSString stringWithFormat:@"%.1f", [[clinicInfo objectForKey:@"distance"] doubleValue]] : @"--"];
    if ([[clinicInfo objectForKey:@"distance"] doubleValue] > 10000)
        label.adjustsFontSizeToFitWidth = YES;
    // Configure the cell...
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *clinicInfo = [[self.clinicsInStates objectForKey:[self.allStates objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    BOOL isRecommend = [[clinicInfo objectForKey:@"recommend"] intValue] > 0;
    return isRecommend ? 142 : 120;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *clinicInfo = [[self.clinicsInStates objectForKey:[self.allStates objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    BOOL isRecommend = [[clinicInfo objectForKey:@"recommend"] intValue] > 0;
    if (isRecommend) {
        cell.backgroundColor = indexPath.row % 2 == 0 ? UIColorFromRGB(0xf8eabf) : UIColorFromRGB(0xf7f0d7);
    } else {
        cell.backgroundColor = indexPath.row % 2 == 0 ? UIColorFromRGB(0xf6f5ef) : UIColorFromRGB(0xfbfaf7);
    }
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
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

#pragma mark - Table view delegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 24)];
    [header setBackgroundColor:UIColorFromRGB(0x5a62d2)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(11, 1, 280, 21)];
    [label setTextColor:[UIColor whiteColor]];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setFont:[Utils boldFont:15]];
    [label setText:[self.allStates objectAtIndex:section]];

    
    [header addSubview:label];
    return header;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Choose map application"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:nil 
                                  otherButtonTitles:@"Open with Google Map", @"Open with Apple Map", nil];
    [actionSheet showInView:self.view];
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    [User currentUser].currentLocation = newLocation;
    GLLog(@"current location %@", [User currentUser].currentLocation);
    [self loadClinicsData];
    [self.tableView reloadData];
    //do something else
    [manager stopUpdatingLocation];
}

#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSIndexPath *selected = [self.tableView indexPathForSelectedRow];
    NSDictionary *clinicInfo = [[_clinicsInStates objectForKey:[_allStates objectAtIndex:selected.section]] objectAtIndex:selected.row ];
    double distance = [[clinicInfo objectForKey:@"distance"] doubleValue];
    CLLocationCoordinate2D rdOfficeLocation = CLLocationCoordinate2DMake([[clinicInfo objectForKey:@"lat"] doubleValue], [[clinicInfo objectForKey:@"lng"] doubleValue]);
//    GLLog(@"nav to %@: %@, %@", clinicInfo, [clinicInfo objectForKey:@"lat"], [clinicInfo objectForKey:@"lng"]);
    switch (buttonIndex) {
        case 0:
        {
            //Google Maps
            //construct a URL using the comgooglemaps schema
            NSURL *url = distance && distance <= DRIVING_THRESHOLD
                ? [NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?daddr=%f,%f&directionsmode=driving", rdOfficeLocation.latitude,rdOfficeLocation.longitude]]
                : [NSURL URLWithString:[NSString stringWithFormat:@"comgooglemaps://?q=%@&center=%f,%f", [[clinicInfo objectForKey:@"address"] stringByReplacingOccurrencesOfString:@" " withString:@"+"], rdOfficeLocation.latitude,rdOfficeLocation.longitude]];
            if (![[UIApplication sharedApplication] canOpenURL:url]) {
                GLLog(@"Google Maps app is not installed");
                //left as an exercise for the reader: open the Google Maps mobile website instead!
                UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Google Map not installed"
                                                               message:@"Please install Google Map first or use Apple Map."
                                                              delegate:self
                                                     cancelButtonTitle:@"ok" 
                                                     otherButtonTitles:nil];
                [alert show];
            } else {
                [[UIApplication sharedApplication] openURL:url];
            }
        }
            break;
        case 1:
        {
            //Apple Maps, using the MKMapItem class
            MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:rdOfficeLocation addressDictionary:nil];
            MKMapItem *item = [[MKMapItem alloc] initWithPlacemark:placemark];
            item.name = [clinicInfo objectForKey:@"name"];
            NSDictionary *options = distance && distance <= DRIVING_THRESHOLD ? @{MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving} : nil;
            [item openInMapsWithLaunchOptions:options];
        }
            break;
        case 2:
            [self.tableView deselectRowAtIndexPath:selected animated:NO];
            return;
        default:
            break;
    }
}

#pragma mark - Handlers
- (IBAction)clickNavigationBack:(id)sender {
    //[Logging log:BTN_CLK_HELP_BACK_ARROW];
    [self.navigationController popViewControllerAnimated:YES from:self];
}

@end
