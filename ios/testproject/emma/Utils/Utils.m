//
//  Utils.m
//  emma
//
//  Created by Ryan Ye on 2/6/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIDeviceUtil/UIDeviceUtil.h>
#import "Utils.h"
#import "DataStore.h"
#import "Network.h"
#import <QuartzCore/QuartzCore.h>

static NSString * const kGLCharactersToBeEscapedInQueryString = @":/?&=;+!@#$()',*";

static NSString * GLPercentEscapedQueryStringKeyFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    static NSString * const kGLCharactersToLeaveUnescapedInQueryStringPairKey = @"[].";
	return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)kGLCharactersToLeaveUnescapedInQueryStringPairKey, (__bridge CFStringRef)kGLCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

static NSString * GLPercentEscapedQueryStringValueFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
	return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)kGLCharactersToBeEscapedInQueryString, CFStringConvertNSStringEncodingToEncoding(encoding));
}

@interface Utils()
+ (NSString *)urlEncodedKeyString:(id)obj;
+ (NSString *)urlEncodedValueString:(id)obj;
+ (NSRange)findPair:(NSString *)pattern inString:(NSString *)source;
@end

@implementation Utils

+ (NSString *)urlEncodedKeyString:(id)obj
{
    NSString *string = [NSString stringWithFormat:@"%@", obj ?: @""];
    return GLPercentEscapedQueryStringKeyFromStringWithEncoding(string, NSUTF8StringEncoding);
}

+ (NSString *)urlEncodedValueString:(id)obj
{
    NSString *string = [NSString stringWithFormat:@"%@", obj ?: @""];
    return GLPercentEscapedQueryStringValueFromStringWithEncoding(string, NSUTF8StringEncoding);
}

+ (NSString *)urlEncodedStringFromDictionary:(NSDictionary *)dict {
    NSMutableArray *parts = [NSMutableArray array];
    for (NSString *key in dict) {
        NSString *val = [dict valueForKey:key];
        NSString *part = [NSString stringWithFormat: @"%@=%@", [self urlEncodedKeyString:key], [self urlEncodedValueString:val]];
        [parts addObject: part];
    }
    return [parts componentsJoinedByString: @"&"];
}

+ (NSString *)makeUrl:(NSString *)url query:(NSDictionary *)query {
    if([url rangeOfString:@"http://"].location == NSNotFound && [url rangeOfString:@"https://"].location == NSNotFound) {
        url = [NSString stringWithFormat:@"%@%@", EMMA_BASE_URL, url];
    }
    if (query && [query count] > 0) {
        url = [NSString stringWithFormat:@"%@?%@", url, [self urlEncodedStringFromDictionary:query]];
    }
    return url;
}

+ (NSString *)makeUrl:(NSString *)url {
    return [Utils makeUrl:url query:nil];
}

+ (NSString *)apiUrl:(NSString *)url query:(NSDictionary *)query {
    if([url rangeOfString:@"http://"].location == NSNotFound && [url rangeOfString:@"https://"].location == NSNotFound) {
        return [Utils makeUrl:[NSString stringWithFormat:@"/api/%@", url] query:query]; 
    }
    return [Utils makeUrl:url query:query]; 
}

+ (NSDictionary *)inverseDict:(NSDictionary *)dict {
    NSMutableDictionary *inverseDict = [[NSMutableDictionary alloc] init];
    for (NSString *attr in dict) {
        [inverseDict setValue:attr forKey:[dict valueForKey:attr]];
    }
    return inverseDict;
}

static NSCache *ImageCache;

+ (UIImage *)image:(UIImage *)image withColor:(UIColor *)color {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, image.size.width, image.size.height);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    CGContextSaveGState(ctx);
    CGContextClipToMask(ctx, area, image.CGImage);
    [color set];
    CGContextFillRect(ctx, area);
    CGContextRestoreGState(ctx);
    // CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    // CGContextDrawImage(ctx, area, image.CGImage);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage *)image:(UIImage *)image withColor:(UIColor *)color withBlendMode:(CGBlendMode)blendMode {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, image.size.width, image.size.height);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    CGContextSaveGState(ctx);
    CGContextClipToMask(ctx, area, image.CGImage);
    [color set];
    CGContextFillRect(ctx, area);
    CGContextRestoreGState(ctx);
    CGContextSetBlendMode(ctx, blendMode);
    CGContextDrawImage(ctx, area, image.CGImage);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (UIImage *)imageNamed:(NSString *)name withColor:(UIColor *)color {
    if (!ImageCache) {
        ImageCache = [[NSCache alloc] init];
    }
    
    const CGFloat *c = CGColorGetComponents(color.CGColor);
    NSString *cache_key = [NSString stringWithFormat:@"_%@_%f_%f_%f_", name, c[0], c[1], c[2]];
    UIImage *img = [ImageCache objectForKey:cache_key];
    if (img) {
        return img;
    }

    UIImage *newImage = [Utils image:[UIImage imageNamed:name] withColor:color];
    
    //write to document directory
    [ImageCache setObject:newImage forKey:cache_key];

    return newImage;
}

+ (UIImage *)imageWithColor:(UIColor *)color andSize:(CGSize)size
{
    UIImage *img = nil;
    
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context,
                                   color.CGColor);
    CGContextFillRect(context, rect);
    
    img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

+ (UIImage *)snapshotOfView:(UIView *)view withMaxSize:(BOOL)maxSize {
    UIWindow *window = [GLUtils keyWindow];
    
    CGSize size = maxSize? window.bounds.size : view.frame.size;
    
    UIGraphicsBeginImageContextWithOptions(size, YES, 1);
    CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationLow);
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


+ (NSAttributedString *)markdownToAttributedText:(NSString *)markdown fontSize:(CGFloat)fontSize color:(UIColor *)color {
   return [self markdownToAttributedText:markdown fontSize:fontSize lineHeight:0 color:color];
}

+ (NSAttributedString *)markdownToAttributedText:(NSString *)markdown fontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight color:(UIColor *)color {
    return [self markdownToAttributedText:markdown fontSize:fontSize lineHeight:lineHeight color:color alignment:NSTextAlignmentLeft];
}

+ (NSAttributedString *)markdownToAttributedText:(NSString *)markdown fontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight color:(UIColor *)color alignment:(NSTextAlignment)alignment {
    NSMutableDictionary *baseAttr = [@{
       NSFontAttributeName : [Utils defaultFont: fontSize],
       NSForegroundColorAttributeName : color,
    } mutableCopy];
    if (lineHeight > 0) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.minimumLineHeight = lineHeight;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = alignment;
        [baseAttr setObject: paragraphStyle forKey:NSParagraphStyleAttributeName];
    }
    NSMutableDictionary *boldAttr = [baseAttr mutableCopy];
    [boldAttr setObject:[Utils boldFont: fontSize] forKey:NSFontAttributeName];
    NSMutableDictionary *semiBoldAttr = [baseAttr mutableCopy];
    [semiBoldAttr setObject:[Utils semiBoldFont: fontSize] forKey:NSFontAttributeName];
    NSMutableDictionary *linkAttr = [baseAttr mutableCopy];
    [linkAttr setObject:[Utils boldFont: fontSize] forKey:NSFontAttributeName];
    [linkAttr setObject:UIColorFromRGB(0x4751CE) forKey:NSForegroundColorAttributeName];
    [linkAttr setObject:[NSNumber numberWithInt:NSUnderlineStyleSingle] forKey:NSUnderlineStyleAttributeName];

    NSDictionary *styleAttrs = @{
        @"**" :  boldAttr,
        @"##" : linkAttr,
        @"$$" : semiBoldAttr,
    };
    NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:markdown attributes:baseAttr];
    for (NSString *ctrlStr in styleAttrs) {
        NSDictionary *attr = [styleAttrs objectForKey:ctrlStr];
        NSRange range = [self findPair:ctrlStr inString:[attrText string]];
        while(range.location != NSNotFound) {
            NSString *subText = [[attrText string] substringWithRange:range];
            subText = [subText stringByReplacingOccurrencesOfString:ctrlStr withString:@""];
            NSAttributedString *attrSubText = [[NSAttributedString alloc] initWithString:subText attributes:attr];
            [attrText replaceCharactersInRange:range withAttributedString:attrSubText];
            range = [self findPair:ctrlStr inString:[attrText string]];
        }
    }
    return attrText;
}

+ (NSRange)findPair:(NSString *)pattern inString:(NSString *)source {
    NSRange start = [source rangeOfString:pattern];
    if (start.location == NSNotFound)
        return NSMakeRange(NSNotFound, 0);
    NSRange end = [source rangeOfString:pattern options:0 range:NSMakeRange(start.location + start.length, source.length - (start.location + start.length))];
    if (end.location == NSNotFound)
        return NSMakeRange(NSNotFound, 0);
    return NSMakeRange(start.location, end.location + end.length - start.location);
}

+ (UIImage *)imageNamed:(NSString *)imageName {
    return [UIImage imageNamed:imageName];
}

+ (UIFont *)defaultFont:(CGFloat)fontSize {
    return [UIFont fontWithName:@"ProximaNova-Regular" size:fontSize];
}

+ (UIFont *)boldFont:(CGFloat)fontSize {
    return [UIFont fontWithName:@"ProximaNova-Bold" size:fontSize];
}

+ (UIFont *)lightFont:(CGFloat)fontSize {
    return [UIFont fontWithName:@"ProximaNova-Light" size:fontSize];
}

+ (UIFont *)semiBoldFont:(CGFloat)fontSize {
    return [UIFont fontWithName:@"ProximaNova-Semibold" size:fontSize];
}

+ (NSInteger)cycleLengthDisplayToModel:(NSInteger)display {
    return display - 1;
}

+ (NSInteger)cycleLengthModelToDisplay:(NSInteger)model {
    return model + 1;
}

+ (void)printViewControllStackFromViewController:(UIViewController *)vc desc:(NSString *)desc {
    UIViewController *_vc = vc;
    while (_vc) {
        GLLog(@"%@", [NSString stringWithFormat:@"%@ %@", desc, _vc]);
        _vc = _vc.parentViewController;
    }
}

+ (void)printViewStackFromView:(UIView *)v desc:(NSString *)desc {
    UIView *_v = v;
    while (_v) {
        GLLog(@"%@", [NSString stringWithFormat:@"%@ %@", desc, _v]);
        _v = _v.superview;
    }
}

+ (id)findFirstPbIndexBefore:(NSString *)dateLabel inPrediction:(NSArray *)predictionData {
    NSInteger count = [predictionData count];
    for (NSInteger i = 0; i < count; i++) {
        NSString *pb = [[predictionData objectAtIndex:i] objectForKey:@"pb"];
        NSInteger cl = [[[predictionData objectAtIndex:i] objectForKey:@"cl"] integerValue];
        NSString *nextPb = [Utils dateLabelAfterDateLabel:pb withDays:cl];
        
        if ([Utils daysBeforeDateLabel:pb sinceDateLabel:dateLabel] > 0) {
            return [NSNumber numberWithInteger: i - 1];
        } else if ([Utils daysBeforeDateLabel:nextPb sinceDateLabel:dateLabel] > 0) {
            return [NSNumber numberWithInteger: i];
        }
    }
    return [NSNumber numberWithInteger:9999];
}

static NSTimeInterval startTime = 0;
+ (void)startProfileTimer {
    startTime = [[NSDate date] timeIntervalSince1970];
}

+ (void)reportElapsedTime:(NSString *)message {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    GLLog(@"%@ %f", message, now - startTime);
}

+ (NSCalendar *)calendar {
//    GLLog(@"Call for calendar !!, thread = %@", [NSOperationQueue currentQueue]);
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSCalendar *cal = [threadDictionary objectForKey:@"calendar"];
    if (!cal) {
        cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        cal.locale = [NSLocale currentLocale];
        [threadDictionary setObject:cal forKey:@"calendar"];
    }
    return cal;
}

+ (void)rotateView:(UIView *)view angle:(CGFloat)angle duration:(CGFloat)d clockwise:(BOOL)clockwise {
    // get current angle and target angle
    CGFloat curAngle = [[view.layer valueForKeyPath:@"transform.rotation"] floatValue] * 360.0 / (M_PI * 2);
    CGFloat tgtAngle = clockwise ? curAngle + angle : curAngle - angle;

    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 * tgtAngle / 360 ];
    rotationAnimation.duration = d;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = 1;
    rotationAnimation.removedOnCompletion = YES;

    RotateAnimation *rotate = [[RotateAnimation alloc] initWithView:view angle:tgtAngle];
    rotationAnimation.delegate = rotate;

    [view.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];

    /*
     // This is a simple way to rotate a view, but can not set direction (clockwise) and can not rotate more than 180
     [UIView animateWithDuration:1.0 animations:^{
     view.transform = CGAffineTransformMakeRotation(M_PI * 2.0 * angle / 360);
     }];
     */
}

+ (UIView *)outline:(UIView *)view {
    if (view) {
        [view.layer setBorderWidth:1.0];
        [view.layer setBorderColor:[[Utils randomColor] CGColor]];
    }
    return view;
}

+ (UIColor *)randomColor {
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    return color;
}

+ (UIColor *)colorFromWebHexValue:(NSString *)hexString
{
    unsigned int val;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    if ([hexString hasPrefix:@"#"]) {
        [scanner setScanLocation:1];
    }
    [scanner scanHexInt:&val];
    return UIColorFromRGB(val);
}

+ (NSString *) UUID {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];    
    NSString *uuid = [defaults objectForKey:@"UUID"];
    if (uuid) {
        return uuid;
    }
    uuid = [[NSUUID UUID] UUIDString];
    [defaults setObject:uuid forKey:@"UUID"];
    [defaults synchronize];
    return uuid;
}

+ (NSString *) generateUUID {
    return [[NSUUID UUID] UUIDString];
}

+ (NSString *) localeString {
    NSLocale *curLocale = [NSLocale currentLocale];
    return curLocale.localeIdentifier;
}

+ (NSString *)modelString
{
    return [UIDeviceUtil hardwareString];
}

static NSString * _appVersion=nil;
static int64_t _appVersionNumber=0;

// we need this func because we don't need get appVersion every time
+ (NSString *)appVersion {
    // "build"  - CFBundleVersion - 
    // "version" - CFBundleShortVersionString - shown in app store
    if (!_appVersion) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        _appVersion = [[bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    }
    return _appVersion;
}

// we need this func because we don't need calculate the version number every time
+ (int64_t)appVersionNumber {
    if (!_appVersionNumber) {
        NSString * version = [Utils appVersion];
        NSArray * builds = [version componentsSeparatedByString:@"."];
        int64_t n = 0;
        for (NSString *s in builds) {
            n = n * 100 + [s intValue];
        }
        _appVersionNumber = n;
    }
    return _appVersionNumber;
}

+ (int64_t)versionToNumber:(NSString *)version {
    NSArray * builds = [version componentsSeparatedByString:@"."];
    int64_t n = 0;
    for (NSString *s in builds) {
        n = n * 100 + [s intValue];
    }
    return n;
}

+ (UIImage *) imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage * img = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return img;
}

+ (NSString *)numberToShortIntString:(long long)num {
    NSString *u = @"";
    NSInteger newNum = 0;
    if (num >= 1000000000) {
        u = @"b";
        newNum = num/1000000000;
    } else if (num >= 1000000) {
        u = @"m";
        newNum = num/1000000;
    } else if (num >= 1000) {
        u = @"k";
        newNum = num/1000;
    } else {
        newNum = num;
    }
    return [NSString stringWithFormat:@"%ld%@", (long)newNum, u];
}

+ (NSString *)numberToShortString:(long long)num {
    NSString *u = @"";
    double_t newNum = (double_t)num;
    if (num > 1000000000) {
        u = @"b";
        newNum = newNum/1000000000;
    } else if (num > 1000000) {
        u = @"m";
        newNum = newNum/1000000;
    } else if (num > 1000) {
        u = @"k";
        newNum = newNum/1000;
    }
    if (newNum > 1000) {
        return [NSString stringWithFormat:@"%ld%@", (long)newNum, u];
    }else if (newNum > 100) {
        return [NSString stringWithFormat:@"%3.f%@", newNum, u];
    } else if (newNum > 10) {
        return [NSString stringWithFormat:@"%2.1f%@", newNum, u];
    } else {
        return [NSString stringWithFormat:@"%1.2f%@", newNum, u];
    }
}

+ (NSString *)trim:(NSString *)aString {
    if (aString) {
        return [aString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    } else
        return nil;
}

+ (BOOL)isValidEmail:(NSString *)string {
    BOOL stricterFilter = YES;
    NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:string];
}
+ (NSString *)numberToSeparatedString:(long long)num {
    NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setFormatterBehavior: NSNumberFormatterBehavior10_4];
    [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
    NSString *numberString = [numberFormatter stringFromNumber: [NSNumber numberWithInteger:num]];
    return numberString;
}

+ (NSString *)numberTo4BytesString:(long long)num {
    return num > 10000 ? [Utils numberToShortString:num] : [Utils numberToSeparatedString:num];
}

+ (BOOL)isConfirmPassword:(NSString *)confirmPassword partialyMatchingPassword:(NSString *)password {
    if (confirmPassword == nil) {
        return YES;
    } else if(password == nil){
        return NO;
    }
    
    if ([confirmPassword length] > [password length]) {
        return NO;
    } else {
        for (NSInteger i=0; i<[confirmPassword length]; i++) {
            unichar c = [confirmPassword characterAtIndex:i];
            unichar p = [password characterAtIndex:i];
            if (c != p) {
                return NO;
            }
        }
    }
    
    return YES;
}


+ (void)performInMainQueueAfter:(NSTimeInterval)seconds callback:(void (^)(void))callback {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC), dispatch_get_main_queue(), callback);
}

+ (NSString *)jsonStringify:(id)stringifiableObj {
    NSString *result = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:stringifiableObj options:0 error:nil] encoding:NSUTF8StringEncoding];
    return result;
}

+ (id)jsonParse:(NSString *)stringified {
    NSData *data = [stringified dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

+ (void)readStringResources:(NSString *)resourceName complete:(ReadResourceCallback) readResouceCallback {
     NSString *filePath = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"txt"];
    if (filePath) {
        NSString *resourceContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        if (resourceContent) {
//            GLLog(@"read content %@", resourceContent);
            readResouceCallback(resourceContent);
        }
    }
}

+ (BOOL)isEmptyString:(NSString *)s {
    return ![Utils isNotEmptyString:s];
}

+ (BOOL)isNotEmptyString:(NSString *)s {
    if ((!s) || ([s isEqualToString:@""])) {
        return NO;
    } else {
        return YES;
    }
}

+ (NSString *)stringByStrippingHtmlTags:(NSString *)string {
    return [string stringByReplacingOccurrencesOfString:@"</?[a-z][^>]*>" withString:@"" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, string.length)];
    
}

+ (void)clearDirectory:(NSString *)directory {
// Remove all files and sub-directory within a specific directory  
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:directory error:&error];
    if (error == nil) {
        for (NSString *path in directoryContents) {
            NSString *fullPath = [directory stringByAppendingPathComponent:path];
            [fileManager removeItemAtPath:fullPath error:&error];
        }
    }
}

+ (void)clearAllAppData {
    // clear core data
    [DataStore deleteDBFile:@"default"];
    // clear NSUserDefaults
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    // clear local files
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [Utils clearDirectory:docDir];
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [Utils clearDirectory:cacheDir];
    NSString *supportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [Utils clearDirectory:supportDir];
}

#pragma mark - String
+ (NSArray *)shuffle:(NSArray *)arr {
    if (!arr) {
        return @[];
    }
    
    srandom((unsigned int)time(NULL));
    NSMutableArray *marr = [NSMutableArray arrayWithArray:arr];
    NSUInteger count = [marr count];
    for (NSUInteger i = 0; i < count; ++i) {
        // Select a random element between i and end of array to swap with.
        NSInteger nElements = count - i;
        NSInteger n = (random() % nElements) + i;
        [marr exchangeObjectAtIndex:i withObjectAtIndex:n];
    }
    
    return [NSArray arrayWithArray:marr];
}


+ (id)getDefaultsForKey:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:key];
}

+ (void)setDefaultsForKey:(NSString *)key withValue:(id)val {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (val != nil) {
        [defaults setObject:val forKey:key];
    }
    else {
        [defaults removeObjectForKey:key];
    }
    [defaults synchronize];
}

+ (long)getSyncableDefautsLastUpdateForKey:(NSString *)key {
    NSString *defaultTimeKey = catstr(key, @"_last_update", nil);
    return [[Utils getDefaultsForKey:defaultTimeKey] longValue];
}

+ (void)setSyncableDefautsForKey:(NSString *)key withValue:(id)val {
    NSString *defaultTimeKey = catstr(key, @"_last_update", nil);
    [self setDefaultsForKey:key withValue:val];
    [self setDefaultsForKey:defaultTimeKey withValue:@([[NSDate date]
        timeIntervalSince1970])];
}

+ (void)syncSyncableDefaultsForKey:(NSString *)key withValue:(id)val
    withLastUpdate:(long)lastUpdate {
    NSString *defaultTimeKey = catstr(key, @"_last_update", nil);
    [self setDefaultsForKey:key withValue:val];
    [self setDefaultsForKey:defaultTimeKey withValue:@(lastUpdate)];
}

+ (void)syncUserDefaultsForUserId:(NSString *)uid token:(NSString *)token{
    
    NSMutableDictionary *syncableDefaults = [@{} mutableCopy];
   
    NSString *hiddensKey = catstr(uid, @"_",
        DEFAULTS_HIDDEN_LOG_KEYS_POSTFIX, nil);
    long lastUpdate = [Utils getSyncableDefautsLastUpdateForKey:hiddensKey];
    NSArray *hiddens = [Utils getDefaultsForKey:hiddensKey];
    syncableDefaults[DEFAULTS_HIDDEN_LOG_KEYS_POSTFIX] = @{
        @"last_update": @(lastUpdate),
        @"content": hiddens ? hiddens : @[]};
    
    NSDictionary *pollIds = [Utils getDefaultsForKey:
        USERDEFAULTS_USER_DAILY_POLL_IDS];
    long pollIdsLastUpdate = [Utils getSyncableDefautsLastUpdateForKey:
        USERDEFAULTS_USER_DAILY_POLL_IDS];
    syncableDefaults[USERDEFAULTS_USER_DAILY_POLL_IDS] = @{
        @"last_update": @(pollIdsLastUpdate),
        @"content": pollIds ? pollIds : @{}};
    
    if ([syncableDefaults count] == 0) {
        return;
    }
    
    NSMutableDictionary *request = [NSMutableDictionary dictionaryWithDictionary:
        @{@"defaults": syncableDefaults}];
    request[@"ut"] = token;
    
    
    [[Network sharedNetwork] post:@"users/client_defaults" data:request requireLogin:NO
        completionHandler:^(NSDictionary *result, NSError *err) {
        
        if (err) {
            return;
        }
        if (!result[@"defaults_to_client"]) {
            return;
        }
        NSDictionary *defaultsToClient = result[@"defaults_to_client"];
        if (defaultsToClient[DEFAULTS_HIDDEN_LOG_KEYS_POSTFIX]) {
            [self _syncDefautsFromServerResult:
                defaultsToClient[DEFAULTS_HIDDEN_LOG_KEYS_POSTFIX]
                forKey:hiddensKey];
        }
        if (defaultsToClient[USERDEFAULTS_USER_DAILY_POLL_IDS]) {
            [self _syncDefautsFromServerResult:
                defaultsToClient[USERDEFAULTS_USER_DAILY_POLL_IDS]
                forKey:USERDEFAULTS_USER_DAILY_POLL_IDS];
        }
    }];
}

+ (void)_syncDefautsFromServerResult:(NSDictionary *)result forKey:
    (NSString *)key {
    long lastUpdate = [result[@"last_update"] longValue];
    NSDictionary *content = result[@"content"];
    [Utils syncSyncableDefaultsForKey:key withValue:content
        withLastUpdate:lastUpdate];
}

+ (void)transmitHiddenDailyLogDefaultsForUserId:(NSString *)uid token:
    (NSString *)token {
    NSString *oldHiddensKey = catstr(token, @"_",
        DEFAULTS_HIDDEN_LOG_KEYS_POSTFIX, nil);
    NSString *newHiddensKey = catstr(uid, @"_",
        DEFAULTS_HIDDEN_LOG_KEYS_POSTFIX, nil);
    NSArray *hiddens = [Utils getDefaultsForKey:oldHiddensKey];
    long lastUpdate = [Utils getSyncableDefautsLastUpdateForKey:oldHiddensKey];
    
    if (!hiddens) {
        return;
    }
    [Utils syncSyncableDefaultsForKey:newHiddensKey withValue:hiddens
        withLastUpdate:lastUpdate];
    [Utils syncSyncableDefaultsForKey:oldHiddensKey withValue:nil
        withLastUpdate:0];
}

+ (NSString *)timeElapsedString:(NSUInteger)timestamp
{
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] - timestamp;
    if (interval < 1.0) {
        return @"Just now";
    }
    if (interval < 60.0) {
        NSUInteger num = floor(interval);
        return [NSString stringWithFormat:@"%lu %@ ago", (unsigned long)num, num > 1 ? @"secs" : @"sec"];
    }
    interval /= 60.0;
    if (interval < 60.0) {
        NSUInteger num = floor(interval);
        return [NSString stringWithFormat:@"%lu %@ ago", (unsigned long)num, num > 1 ? @"mins" : @"min"];
    }
    interval /= 60.0;
    if (interval < 24.0) {
        NSUInteger num = floor(interval);
        return [NSString stringWithFormat:@"%lu %@ ago", (unsigned long)num, num > 1 ? @"hours" : @"hour"];
    }
    NSString *dateFormatString = [NSDateFormatter dateFormatFromTemplate:@"EEEdMMM" options:0 locale:[NSLocale currentLocale]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    [dateFormatter setDateFormat:dateFormatString];
    return [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timestamp]];
}



+ (NSString *)displayOrder:(NSInteger)order {
    if (order <= 0) {
        return @"";
    } else if (order == 1) {
        return @"1st";
    } else if (order == 2) {
        return @"2nd";
    } else if (order == 3) {
        return @"3rd";
    } else
        return [NSString stringWithFormat:@"%ldth", order];
}

+ (NSDate *)dateFromTtcStartString:(NSString *)ttcStartString {
    NSArray *ttcStartStringSplits = [ttcStartString componentsSeparatedByString:@" "];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    if ([ttcStartStringSplits count] != 2 ||
        ![formatter numberFromString:ttcStartStringSplits[0]] ||
        !DURATION_UNITS[[ttcStartStringSplits[1] lowercaseString]]) {
        return nil;
    }
    NSInteger duration = [ttcStartStringSplits[0] integerValue];
    NSString *durationUnits = [ttcStartStringSplits[1] lowercaseString];
    NSDate *truncatedToday = [[NSDate date] truncatedSelf];
    if ([durationUnits isEqual:@"week"] || [durationUnits isEqual:@"weeks"]) {
        return [self dateByAddingDays:-7 * duration toDate:truncatedToday];
    }
    else if([durationUnits isEqual:@"month"] || [durationUnits isEqual:@"months"]) {
        return [self dateByAddingMonths:-duration toDate:truncatedToday];
    }
    else {
        return [self dateByAddingYears:-duration toDate:truncatedToday];
    }
}

+ (NSString *)ttcStartStringFromDate:(NSDate *)ttcStartDate {
    NSInteger daysFromNow = [[NSDate date] timeIntervalSinceDate:ttcStartDate] / 86400;
    CGFloat approximatedWeek = roundf(daysFromNow / 7.0f);
    CGFloat approximatedMonths = roundf(daysFromNow / 30.0f);
    CGFloat approximatedYears = roundf(daysFromNow / 365.0f);
    if ((NSInteger)approximatedWeek == 0) {
        return @"0 weeks";
    }
    if ((NSInteger)approximatedWeek == 1) {
        return @"1 week";
    }
    if (approximatedYears > 1) {
        return [NSString stringWithFormat:@"%ld %@", (NSInteger)approximatedYears, @"years"];
    }
    if (approximatedMonths >= 4 || (NSInteger)approximatedWeek % 4 == 0) {
        return [NSString stringWithFormat:@"%ld %@", (NSInteger)approximatedMonths,
                ((NSInteger)approximatedMonths == 1 ? @"month" : @"months")];
    }
    return [NSString stringWithFormat:@"%ld %@", (NSInteger)approximatedWeek, @"weeks"];
}

+ (CGFloat)calculateBmiWithHeightInCm:(CGFloat)h weightInKg:(CGFloat)w {
    return w * 10000.0 / (h * h);
}

+ (void)writeString:(NSString *)str toDomainFile:(NSString *)fileName {
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [NSString stringWithFormat:@"%@/%@.plist", docDir, fileName];
    [str writeToFile:plistPath
          atomically:YES
            encoding:NSUTF8StringEncoding
               error:nil];
}

+ (void)imageViewRotateUpDown:(UIImageView *)imageView {
    imageView.transform = CGAffineTransformMakeScale(1, -1);
}

+ (void)imageViewRotateLeftRight:(UIImageView *)imageView {
    imageView.transform = CGAffineTransformMakeScale(-1, 1);
}


+ (NSString *)formatedWithFormat:(NSString *)format date:(NSDate *)date {
    NSMutableDictionary *threadDictionary = [[NSThread currentThread]
        threadDictionary];
    NSDateFormatter *formatter = [threadDictionary objectForKey:@"dateFormatter"];
    if (!formatter) {
        formatter = [[NSDateFormatter alloc] init];
        NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:
            @"en_US"];
        [formatter setLocale:usLocale];
        [threadDictionary setObject:formatter forKey:@"dateFormatter"];
    }
    [formatter setDateFormat:format];
    return [formatter stringFromDate:date];
}

+ (NSArray *)getHslaFromUIColor:(UIColor *)color
{
    CGFloat hue;
    CGFloat saturation;
    CGFloat brightness;
    CGFloat alpha;
    BOOL success = [color getHue:&hue saturation:&saturation brightness:
        &brightness alpha:&alpha];
    if (!success) {
        return @[@(-1), @(-1), @(-1), @(-1)];
    }
    else {
        return @[@(hue), @(saturation), @(brightness), @(alpha)];
    }
}

+ (UIColor *)brighterAndUnsaturatedColor:(UIColor *)color
{
    NSArray *hsla = [Utils getHslaFromUIColor:color];
    UIColor *result = [UIColor colorWithHue:[hsla[0] floatValue]
        saturation:[hsla[1] floatValue] * 0.15f
        brightness:1.0f alpha:[hsla[3] floatValue]];
    return result;
}

@end

@interface RotateAnimation ()
@end
@implementation RotateAnimation
- (id)initWithView:(UIView *)view angle:(CGFloat)tgtAngle{
    self.rotateView = view;
    self.tgtAngle = tgtAngle;
    while (self.tgtAngle > 360) {
        self.tgtAngle -= 360;
    }
    while (self.tgtAngle < -360) {
        self.tgtAngle += 360;
    }
    return self;
}
- (void)animationDidStop:(CABasicAnimation*)anim finished:(BOOL)flag {
    self.rotateView.transform = CGAffineTransformMakeRotation(M_PI*2*self.tgtAngle/360);
}
@end

@implementation UIView(GradientBackground)
- (void)setGradientBackground:(UIColor *)colorOne toColor:(UIColor *)colorTwo {
    NSArray *colors = [NSArray arrayWithObjects:(id)colorOne.CGColor, colorTwo.CGColor, nil];
    NSArray *locations = [NSArray arrayWithObjects:@(0.0), @(1.0), nil];
    CAGradientLayer *bgLayer = [CAGradientLayer layer];
    bgLayer.colors = colors;
    bgLayer.locations = locations;
    bgLayer.frame = self.layer.bounds;
    bgLayer.cornerRadius = self.layer.cornerRadius;
    [self.layer insertSublayer:bgLayer atIndex:0];
}

- (void)removeGradientBackground
{
    for (CALayer *layer in self.layer.sublayers) {
        if ([layer isKindOfClass:[CAGradientLayer class]]) {
            [layer removeFromSuperlayer];
        }
    }
}
@end
