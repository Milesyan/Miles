//
//  AvailableClinicsTableViewController.m
//  emma
//
//  Created by Xin Zhao on 13-4-5.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "AvailableClinicsTableViewController.h"
#import "Utils.h"
#import "User.h"
#import "Logging.h"
#import "ClinicsManager.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#define MILES_PER_METER 0.000621371192
#define DISTANCE_THRESHOLD 500
#define DRIVING_THRESHOLD 200

typedef enum
{
    AvailableClinicsStatusNormal = 1,
    AvailableClinicsStatusNoLocation,
    AvailableClinicsStatusNoClose
}AvailableClinicsStatus;

@interface AvailableClinicsTableViewController () <CLLocationManagerDelegate, UIActionSheetDelegate>

- (IBAction)seeAllPressed:(id)sender;

@property (strong, nonatomic) NSMutableArray *clinicsData;
@property (strong, nonatomic) CLLocationManager *locationManager;
//@property (strong, nonatomic) CLLocation *currentLocation;

@end

@implementation AvailableClinicsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    
    return self;
}

#pragma mark - Getters
- (void)loadClinicsData {
    _clinicsData = [NSMutableArray arrayWithCapacity:5];
    NSDictionary *dictionary;
    NSSortDescriptor *distanceSortDesc = [NSSortDescriptor sortDescriptorWithKey:@"distance" ascending:YES];
    NSSortDescriptor *recommendSortDesc = [NSSortDescriptor sortDescriptorWithKey:@"recommend" ascending:NO];
    
    dictionary = [ClinicsManager readClinics];
    
    for (id state in dictionary) {
        NSArray *clinicsInState = [dictionary objectForKey:state];
        for (int idx = 0; idx < [clinicsInState count]; idx++) {
            NSDictionary *clinic = [clinicsInState objectAtIndex:idx];
            if (![clinic objectForKey:@"lat"]) {
                continue;
            }
            double lat = [[clinic objectForKey:@"lat"] doubleValue];
            double lng = [[clinic objectForKey:@"lng"] doubleValue];
            CLLocationDistance distance = [[User currentUser].currentLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:lat longitude:lng]] * MILES_PER_METER;
            
            if (distance <= DISTANCE_THRESHOLD) {
                int recommend = 0;
                if ([clinic objectForKey:@"recommend"]) {
                    recommend = [[clinic objectForKey:@"recommend"] intValue];
                }
                NSDictionary *convertedClinic = @{
                                                  @"name": [clinic objectForKey:@"name"],
                                                  @"address": [clinic objectForKey:@"address"],
                                                  @"distance":[NSNumber numberWithDouble:distance],
                                                  @"lat":[NSNumber numberWithDouble:lat],
                                                  @"lng":[NSNumber numberWithDouble:lng],
                                                  @"recommend": @(recommend)
                                                  };
                if ([_clinicsData count] < 10 ) {
                    [_clinicsData addObject:convertedClinic];
                    [_clinicsData sortUsingDescriptors:@[distanceSortDesc]];
                } else if (distance < [[[_clinicsData objectAtIndex:9] objectForKey:@"distance"] doubleValue]) {
                    [_clinicsData replaceObjectAtIndex:9 withObject:convertedClinic];
                    [_clinicsData sortUsingDescriptors:@[distanceSortDesc]];
                }
            }
        }
    }
    [_clinicsData sortUsingDescriptors:@[recommendSortDesc]];
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
        // read "foo.plist" from application bundle
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // logging
    [Logging log:PAGE_IMP_HELP_CLINICS_NEAR];
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
    return [self availableClinicsStatus] == AvailableClinicsStatusNormal ? [self.clinicsData count] : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AvailableClinicsStatus clinicsStatus = [self availableClinicsStatus];
    BOOL isRecommend = NO;
    NSDictionary * clinicInfo = nil;
    NSString *cellIdentifier = nil;
    
    // 1. get cell
    if (clinicsStatus == AvailableClinicsStatusNoClose) {
        cellIdentifier = @"noCloseEnough";
    } else if (clinicsStatus == AvailableClinicsStatusNoLocation) {
        cellIdentifier = @"noLocation";
    } else {
        // AvailableClinicsStatusNormal
        clinicInfo = [self.clinicsData objectAtIndex:indexPath.row];
        isRecommend = [[clinicInfo objectForKey:@"recommend"] intValue] > 0;
        cellIdentifier = isRecommend ? CLINIC_TABLE_RECOMMEND_IDENTIFIER : CLINIC_TABLE_CELL_IDENTIFIER;
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    // 2. configure cell if it is normal.
    if (clinicsStatus == AvailableClinicsStatusNormal) {
        UILabel *label = (UILabel *)[cell viewWithTag:100];
        [label setAdjustsFontSizeToFitWidth:NO];
        [label setLineBreakMode:NSLineBreakByTruncatingTail];
        [label setText:[clinicInfo objectForKey:@"name"]];
        label = (UILabel *)[cell viewWithTag:200];
        [label setAdjustsFontSizeToFitWidth:NO];
        [label setLineBreakMode:NSLineBreakByTruncatingTail];
        [label setText:[clinicInfo objectForKey:@"address"]];
        label = (UILabel *)[cell viewWithTag:300];
        [label setText:[NSString stringWithFormat:@"%.1f", [[[self.clinicsData objectAtIndex:indexPath.row] objectForKey:@"distance"] doubleValue]]];
    }
    // Configure the cell...
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self availableClinicsStatus] == AvailableClinicsStatusNormal) {
        NSDictionary * clinicInfo = [self.clinicsData objectAtIndex:indexPath.row];
        BOOL isRecommend = [[clinicInfo objectForKey:@"recommend"] intValue] > 0;
        return isRecommend ? 142 : 120;
    } else {
        return 120;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self availableClinicsStatus] == AvailableClinicsStatusNormal) {
        NSDictionary * clinicInfo = [self.clinicsData objectAtIndex:indexPath.row];
        BOOL isRecommend = [[clinicInfo objectForKey:@"recommend"] intValue] > 0;
        if (isRecommend) {
            cell.backgroundColor = indexPath.row % 2 == 0 ? UIColorFromRGB(0xf8eabf) : UIColorFromRGB(0xf7f0d7);
        } else {
            cell.backgroundColor = indexPath.row % 2 == 0 ? UIColorFromRGB(0xf6f5ef) : UIColorFromRGB(0xfbfaf7);
        }
    } else {
        cell.backgroundColor = indexPath.row % 2 == 0 ? UIColorFromRGB(0xf6f5ef) : UIColorFromRGB(0xfbfaf7);
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    float headerHeight = 24;
    float headerX = 0;
    float headerContainerHeight = 24 + headerX;
    NSString *title = nil;
    title = @"Closest to you";
              
    UIView *headerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, headerContainerHeight)];
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, headerX, SCREEN_WIDTH, headerHeight)];
    [header setBackgroundColor:UIColorFromRGB(0x5a62d2)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(11, 1, 280, 21)];
    [label setTextColor:[UIColor whiteColor]];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setFont:[Utils boldFont:15]];
    
    [label setText: title];
    
    [header addSubview:label];
    [headerContainer addSubview:header];
    return headerContainer;
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
    NSDictionary *clinicInfo = [self.clinicsData objectAtIndex:selected.row ];
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
    // [Logging log:BTN_CLK_HELP_BACK_ARROW];
    [self.navigationController popViewControllerAnimated:YES from:self];
}

- (IBAction)seeAllPressed:(id)sender {
    //[Logging log:BTN_CLK_HELP_CLINICS_ALL];
}

#pragma mark
- (AvailableClinicsStatus) availableClinicsStatus{
    if (![User currentUser].currentLocation) {
        return AvailableClinicsStatusNoLocation;
    } else if ([self.clinicsData count]) {
        return AvailableClinicsStatusNormal;
    } else {
        return AvailableClinicsStatusNoClose;
        
    }
}

@end
