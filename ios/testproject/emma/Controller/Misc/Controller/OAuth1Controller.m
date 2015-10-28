//
//  OAuth1Controller.m
//  emma
//
//  Created by Eric Xu on 3/11/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "OAuth1Controller.h"
#import "NSString+URLEncoding.h"
#include "hmac.h"
#include "Base64Transcoder.h"
#import <GLFoundation/GLUtils.h>

typedef void (^WebWiewDelegateHandler)(NSDictionary *oauthParams);

#define OAUTH_CALLBACK       @"https://glowing.com"
//#define CONSUMER_KEY         @"15a2a4fefe294a50bbf2f2ac9de3ef32"
//#define CONSUMER_SECRET      @"115c740c4d6d4ab09be0e5b08ee11c4b"
//#define AUTH_URL             @"https://api.fitbit.com/"
//#define REQUEST_TOKEN_URL    @"oauth/request_token"
//#define AUTHENTICATE_URL     @"oauth/authorize"
//#define ACCESS_TOKEN_URL     @"oauth/access_token"
//#define API_URL              @"http://api.fitbit.com/"
#define OAUTH_SCOPE_PARAM    @""

#define REQUEST_TOKEN_METHOD @"POST"
#define ACCESS_TOKEN_METHOD  @"POST"


static NSString * CHPercentEscapedQueryStringPairMemberFromStringWithEncoding(NSString *string, NSStringEncoding encoding) {
    static NSString * const kCHCharactersToBeEscaped = @":/?&=;+!@#$()~";
    static NSString * const kCHCharactersToLeaveUnescaped = @"[].";
    
	return (__bridge_transfer  NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, (__bridge CFStringRef)kCHCharactersToLeaveUnescaped, (__bridge CFStringRef)kCHCharactersToBeEscaped, CFStringConvertNSStringEncodingToEncoding(encoding));
}

#pragma mark -

@interface CHQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (id)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding;
@end

@implementation CHQueryStringPair
@synthesize field = _field;
@synthesize value = _value;

- (id)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.field = field;
    self.value = value;
    
    return self;
}

- (NSString *)URLEncodedStringValueWithEncoding:(NSStringEncoding)stringEncoding {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return CHPercentEscapedQueryStringPairMemberFromStringWithEncoding([self.field description], stringEncoding);
    } else {
        return [NSString stringWithFormat:@"%@=%@", CHPercentEscapedQueryStringPairMemberFromStringWithEncoding([self.field description], stringEncoding), CHPercentEscapedQueryStringPairMemberFromStringWithEncoding([self.value description], stringEncoding)];
    }
}

@end

#pragma mark -

extern NSArray * CHQueryStringPairsFromDictionary(NSDictionary *dictionary);
extern NSArray * CHQueryStringPairsFromKeyAndValue(NSString *key, id value);

NSString * CHQueryStringFromParametersWithEncoding(NSDictionary *parameters, NSStringEncoding stringEncoding) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (CHQueryStringPair *pair in CHQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValueWithEncoding:stringEncoding]];
    }
    
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * CHQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return CHQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * CHQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    if([value isKindOfClass:[NSDictionary class]]) {
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(caseInsensitiveCompare:)];
        [[[value allKeys] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]] enumerateObjectsUsingBlock:^(id nestedKey, NSUInteger idx, BOOL *stop) {
            id nestedValue = [value objectForKey:nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:CHQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }];
    } else if([value isKindOfClass:[NSArray class]]) {
        [value enumerateObjectsUsingBlock:^(id nestedValue, NSUInteger idx, BOOL *stop) {
            [mutableQueryStringComponents addObjectsFromArray:CHQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }];
    } else {
        [mutableQueryStringComponents addObject:[[CHQueryStringPair alloc] initWithField:key value:value]];
    }
    
    return mutableQueryStringComponents;
}


static inline NSDictionary *CHParametersFromQueryString(NSString *queryString)
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (queryString)
    {
        NSScanner *parameterScanner = [[NSScanner alloc] initWithString:queryString];
        NSString *name = nil;
        NSString *value = nil;
        
        while (![parameterScanner isAtEnd]) {
            name = nil;
            [parameterScanner scanUpToString:@"=" intoString:&name];
            [parameterScanner scanString:@"=" intoString:NULL];
            
            value = nil;
            [parameterScanner scanUpToString:@"&" intoString:&value];
            [parameterScanner scanString:@"&" intoString:NULL];
            
            if (name && value)
            {
                [parameters setValue:[value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                              forKey:[name stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            }
        }
    }
    return parameters;
}


@interface OAuth1Controller () {
    
}

@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@property (nonatomic, strong) WebWiewDelegateHandler delegateHandler;

@property (nonatomic, strong) NSString *consumerKey;
@property (nonatomic, strong) NSString *consumerSecret;
@property (nonatomic, strong) NSString *authUrl;
@property (nonatomic, strong) NSString *requestTokenPath;
@property (nonatomic, strong) NSString *authenticatePath;
@property (nonatomic, strong) NSString *accessTokenPath;
@property (nonatomic, strong) NSString *callbackUrl;

@property (nonatomic, strong) NSString *apiUrl;
@property (nonatomic, strong) NSString *oauthToken;
@property (nonatomic, strong) NSString *oauthSecret;

@property (nonatomic, strong) AuthenticateCallback authCallback;
@property (nonatomic, strong) GetCallback getCallback;

@end

@implementation OAuth1Controller

static OAuth1Controller *_inst;
+ (OAuth1Controller *)sharedInstance {
    if (!_inst) {
        _inst = [[OAuth1Controller alloc] initWithNibName:@"OAuth1Controller" bundle:nil];
    }
    
    return _inst;
}

+ (void)getFromAPIUrl:(NSString *)apiUrl
                 path:(NSString *)path
           parameters:(NSDictionary *)parameters
      WithConsumerKey:(NSString *)consumerKey
       consumerSecret:(NSString *)consumerSecret
           oauthToken:(NSString *)oauthToken
          oauthSecret:(NSString *)oauthSecret
          andCallback:(GetCallback)callback {
    OAuth1Controller *inst = [OAuth1Controller sharedInstance];
    inst.apiUrl = apiUrl;
    inst.consumerKey = consumerKey;
    inst.consumerSecret = consumerSecret;
    inst.oauthToken = oauthToken;
    inst.oauthSecret = oauthSecret;
    inst.getCallback = callback;
    
    [inst get:path withParameters:parameters andCallback:callback];
}

- (void)get:(NSString *)path withParameters:(NSDictionary *)parameters andCallback:(GetCallback)cb {
    // Build authorized request based on path, parameters, tokens, timestamp etc.
    NSURLRequest *preparedRequest = [OAuth1Controller preparedRequestForPath:path
                                                                  parameters:parameters
                                                                  HTTPmethod:@"GET"
                                                                  oauthToken:self.oauthToken
                                                                 oauthSecret:self.oauthSecret];
    
    if (!preparedRequest) {
        return;
    }
    // Send the request and log response when received
    [NSURLConnection sendAsynchronousRequest:preparedRequest
                                       queue:NSOperationQueue.mainQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               dispatch_async(dispatch_get_main_queue(), ^{
//                                   self.responseTextView.text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                   GLLog(@"data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                                   if (cb) {
                                       cb(data? [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]: @{}, error);
                                   }

                                   if (error) GLLog(@"Error in API request: %@", error.localizedDescription);
                               });
                           }];

}

+ (void)authWithConsumerKey:(NSString *)consumerKey
             consumerSecret:(NSString *)consumerSecret
                    authUrl:(NSString *)authUrl
           requestTokenPath:(NSString *)requestTokenPath
           authenticatePath:(NSString *)authenticatePath
            accessTokenPath:(NSString *)accessTokenPath
                callbackURL:(NSString *)callbackUrl
           andCallbackBlock:(AuthenticateCallback)authenticateCallback;
{
    OAuth1Controller *inst = [OAuth1Controller sharedInstance];
    inst.consumerKey = consumerKey;
    inst.consumerSecret = consumerSecret;
    inst.authUrl = authUrl;
    inst.requestTokenPath = requestTokenPath;
    inst.authenticatePath = authenticatePath;
    inst.accessTokenPath = accessTokenPath;
    inst.callbackUrl = callbackUrl;
    inst.authCallback = authenticateCallback;
    
    [inst authWithCallback:authenticateCallback];
}

- (void)authWithCallback:(AuthenticateCallback) cb{
    if (self.view.superview) {
        return;
    }

    self.view.frame = [GLUtils keyWindow].frame;
    self.view.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT*1.5);
    self.view.alpha = 1.0;
    [[GLUtils keyWindow] addSubview:self.view];

    [UIView animateWithDuration:0.3 animations:^{
        self.view.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT*0.5);
    }completion:^(BOOL finished) {
        [self loginWithWebView:self.webView completion:^(NSDictionary *oauthTokens, NSError *error) {
            if (error)
            {
                GLLog(@"Error authenticating: %@", error.localizedDescription);
            } else if (cb) {
                cb(oauthTokens, error);
            }
            
            [UIView animateWithDuration:0.3 animations:^{
                self.view.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT * 1.5);
            } completion:^(BOOL finished) {
                [self.view removeFromSuperview];
            }];
        }];

    }];
}



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (IBAction)cancel:(id)sender {
//    [self dismissViewControllerAnimated:YES completion:nil];
    [UIView animateWithDuration:0.3 animations:^{
        self.view.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT * 1.5);
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        if (self.authCallback) {
            self.authCallback(@{}, [[NSError alloc] initWithDomain:@"" code:1 userInfo:@{}]);
        }
    }];
}


- (void)loginWithWebView:(UIWebView *)webWiew completion:(void (^)(NSDictionary *oauthTokens, NSError *error))completion
{
//    self.webView = webWiew;
//    self.webView.delegate = self;
    
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.loadingIndicator.color = [UIColor grayColor];
    [self.loadingIndicator startAnimating];
    self.loadingIndicator.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT * 0.5);
    [self.webView addSubview:self.loadingIndicator];
    
    [self obtainRequestTokenWithCompletion:^(NSError *error, NSDictionary *responseParams)
     {
         GLLog(@"obtainRequestToken: %@", responseParams);
         NSString *oauth_token_secret = responseParams[@"oauth_token_secret"];
         NSString *oauth_token = responseParams[@"oauth_token"];
         if (oauth_token_secret
             && oauth_token)
         {
             [self authenticateToken:oauth_token withCompletion:^(NSError *error, NSDictionary *responseParams)
              {
                  GLLog(@"authenticateToken: %@", responseParams);
                  if (!error)
                  {
                      [self requestAccessToken:oauth_token_secret
                                    oauthToken:responseParams[@"oauth_token"]
                                 oauthVerifier:responseParams[@"oauth_verifier"]
                                    completion:^(NSError *error, NSDictionary *responseParams)
                       {
                           GLLog(@"requestAccessToken: %@", responseParams);
                           completion(responseParams, error);
                       }];
                  }
                  else
                  {
                      completion(responseParams, error);
                  }
              }];
         }
         else
         {
             if (!error) error = [NSError errorWithDomain:@"oauth.requestToken" code:0 userInfo:@{@"userInfo" : @"oauth_token and oauth_token_secret were not both returned from request token step"}];
             completion(responseParams, error);
         }
     }];
}


#pragma mark - Step 1 Obtaining a request token
- (void)obtainRequestTokenWithCompletion:(void (^)(NSError *error, NSDictionary *responseParams))completion
{
    NSString *request_url = [self.authUrl stringByAppendingString:self.requestTokenPath];
    NSString *oauth_consumer_secret = self.consumerSecret;
    
    NSMutableDictionary *allParameters = [self.class standardOauthParameters];
    if ([OAUTH_SCOPE_PARAM length] > 0) [allParameters setValue:OAUTH_SCOPE_PARAM forKey:@"scope"];
    
    NSString *parametersString = CHQueryStringFromParametersWithEncoding(allParameters, NSUTF8StringEncoding);
    
    NSString *baseString = [REQUEST_TOKEN_METHOD stringByAppendingFormat:@"&%@&%@", request_url.utf8AndURLEncode, parametersString.utf8AndURLEncode];
    NSString *secretString = [oauth_consumer_secret.utf8AndURLEncode stringByAppendingString:@"&"];
    NSString *oauth_signature = [self.class signClearText:baseString withSecret:secretString];
    [allParameters setValue:oauth_signature forKey:@"oauth_signature"];
    
    parametersString = CHQueryStringFromParametersWithEncoding(allParameters, NSUTF8StringEncoding);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:request_url]];
    request.HTTPMethod = REQUEST_TOKEN_METHOD;
    
    NSMutableArray *parameterPairs = [NSMutableArray array];
    for (NSString *name in allParameters) {
        NSString *aPair = [name stringByAppendingFormat:@"=\"%@\"", [allParameters[name] utf8AndURLEncode]];
        [parameterPairs addObject:aPair];
    }
    NSString *oAuthHeader = [@"OAuth " stringByAppendingFormat:@"%@", [parameterPairs componentsJoinedByString:@", "]];
    [request setValue:oAuthHeader forHTTPHeaderField:@"Authorization"];
    GLLog(@"request.header:%@", request.allHTTPHeaderFields);
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               NSString *reponseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                               completion(nil, CHParametersFromQueryString(reponseString));
                           }];
}

#pragma mark - Step 2 Show login to the user to authorize our app
- (void)authenticateToken:(NSString *)oauthToken withCompletion:(void (^)(NSError *error, NSDictionary *responseParams))completion
{
    NSString *oauth_callback = OAUTH_CALLBACK;
    NSString *authenticate_url = [self.authUrl stringByAppendingString:self.authenticatePath];
    authenticate_url = [authenticate_url stringByAppendingFormat:@"?oauth_token=%@", oauthToken];
    authenticate_url = [authenticate_url stringByAppendingFormat:@"&oauth_callback=%@", oauth_callback.utf8AndURLEncode];
    authenticate_url = [authenticate_url stringByAppendingFormat:@"&display=touch"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:authenticate_url]];
    [request setValue:[NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], (__bridge id)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey) ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.0f)] forHTTPHeaderField:@"User-Agent"];
    
    _delegateHandler = ^(NSDictionary *oauthParams) {
        if (oauthParams[@"oauth_verifier"] == nil) {
            NSError *authenticateError = [NSError errorWithDomain:@"com.ideaflasher.oauth.authenticate" code:0 userInfo:@{@"userInfo" : @"oauth_verifier not received and/or user denied access"}];
            completion(authenticateError, oauthParams);
        } else {
            completion(nil, oauthParams);
        }
    };
    [self.webView loadRequest:request];
}



#pragma mark - Webview delegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    GLLog(@"fail:%@", error);
//    [[[UIAlertView alloc] initWithTitle:@"Failed to open url" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    GLLog(@"loaded");
    [self.loadingIndicator removeFromSuperview];
    self.loadingIndicator = nil;
}

#pragma mark Used to detect call back in step 2
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (_delegateHandler) {
        // For other Oauth 1.0a service providers than LinkedIn, the call back URL might be part of the query of the URL (after the "?"). In this case use index 1 below. In any case GLLog the request URL after the user taps 'Allow'/'Authenticate' after he/she entered his/her username and password and see where in the URL the call back is. Note for some services the callback URL is set once on their website when registering an app, and the OAUTH_CALLBACK set here is ignored.
        NSString *urlWithoutQueryString = [request.URL.absoluteString componentsSeparatedByString:@"?"][0];
        if ([urlWithoutQueryString rangeOfString:OAUTH_CALLBACK].location != NSNotFound)
        {
            NSString *queryString = [request.URL.absoluteString substringFromIndex:[request.URL.absoluteString rangeOfString:@"?"].location + 1];
            NSDictionary *parameters = CHParametersFromQueryString(queryString);
            
            _delegateHandler(parameters);
            _delegateHandler = nil;
            
            return NO;
        }
    }
    return YES;
}


#pragma mark - Step 3 Request access token now that user has authorized the app
- (void)requestAccessToken:(NSString *)oauth_token_secret
                oauthToken:(NSString *)oauth_token
             oauthVerifier:(NSString *)oauth_verifier
                completion:(void (^)(NSError *error, NSDictionary *responseParams))reqCompletion
{
    NSString *access_url = [self.authUrl stringByAppendingString:self.accessTokenPath];
    NSString *oauth_consumer_secret = self.consumerSecret;
    
    NSMutableDictionary *allParameters = [self.class standardOauthParameters];
    [allParameters setValue:oauth_verifier forKey:@"oauth_verifier"];
    [allParameters setValue:oauth_token    forKey:@"oauth_token"];
    
    NSString *parametersString = CHQueryStringFromParametersWithEncoding(allParameters, NSUTF8StringEncoding);
    
    NSString *baseString = [ACCESS_TOKEN_METHOD stringByAppendingFormat:@"&%@&%@", access_url.utf8AndURLEncode, parametersString.utf8AndURLEncode];
    NSString *secretString = [oauth_consumer_secret.utf8AndURLEncode stringByAppendingFormat:@"&%@", oauth_token_secret.utf8AndURLEncode];
    NSString *oauth_signature = [self.class signClearText:baseString withSecret:secretString];
    [allParameters setValue:oauth_signature forKey:@"oauth_signature"];
    
    parametersString = CHQueryStringFromParametersWithEncoding(allParameters, NSUTF8StringEncoding);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:access_url]];
    request.HTTPMethod = ACCESS_TOKEN_METHOD;
    
    NSMutableArray *parameterPairs = [NSMutableArray array];
    for (NSString *name in allParameters)
    {
        NSString *aPair = [name stringByAppendingFormat:@"=\"%@\"", [allParameters[name] utf8AndURLEncode]];
        [parameterPairs addObject:aPair];
    }
    NSString *oAuthHeader = [@"OAuth " stringByAppendingFormat:@"%@", [parameterPairs componentsJoinedByString:@", "]];
    [request setValue:oAuthHeader forHTTPHeaderField:@"Authorization"];
    GLLog(@"request.header:%@", request.allHTTPHeaderFields);
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                               reqCompletion(nil, CHParametersFromQueryString(responseString));
                           }];
}


+ (NSMutableDictionary *)standardOauthParameters
{
    NSString *oauth_timestamp = [NSString stringWithFormat:@"%i", (NSUInteger)[NSDate.date timeIntervalSince1970]];
    NSString *oauth_nonce = [NSString getNonce];
    NSString *oauth_consumer_key = [[OAuth1Controller sharedInstance] consumerKey];
    NSString *oauth_signature_method = @"HMAC-SHA1";
    NSString *oauth_version = @"1.0";
    
    NSMutableDictionary *standardParameters = [NSMutableDictionary dictionary];
    [standardParameters setValue:oauth_consumer_key     forKey:@"oauth_consumer_key"];
    [standardParameters setValue:oauth_nonce            forKey:@"oauth_nonce"];
    [standardParameters setValue:oauth_signature_method forKey:@"oauth_signature_method"];
    [standardParameters setValue:oauth_timestamp        forKey:@"oauth_timestamp"];
    [standardParameters setValue:oauth_version          forKey:@"oauth_version"];
    
    return standardParameters;
}


#pragma mark build authorized API-requests
+ (NSURLRequest *)preparedRequestForPath:(NSString *)path
                              parameters:(NSDictionary *)queryParameters
                              HTTPmethod:(NSString *)HTTPmethod
                              oauthToken:(NSString *)oauth_token
                             oauthSecret:(NSString *)oauth_token_secret
{
    if (!HTTPmethod
        || !oauth_token) return nil;
    
    NSMutableDictionary *allParameters = [self standardOauthParameters];
    allParameters[@"oauth_token"] = oauth_token;
    if (queryParameters) [allParameters addEntriesFromDictionary:queryParameters];
    
    NSString *parametersString = CHQueryStringFromParametersWithEncoding(allParameters, NSUTF8StringEncoding);
    
    NSString *request_url = [OAuth1Controller sharedInstance].apiUrl;
    if (path) request_url = [request_url stringByAppendingString:path];
    NSString *oauth_consumer_secret = [OAuth1Controller sharedInstance].consumerSecret;
    NSString *baseString = [HTTPmethod stringByAppendingFormat:@"&%@&%@", request_url.utf8AndURLEncode, parametersString.utf8AndURLEncode];
    GLLog(@"baseString: %@", baseString);
    NSString *secretString = [oauth_consumer_secret.utf8AndURLEncode stringByAppendingFormat:@"&%@", oauth_token_secret.utf8AndURLEncode];
    NSString *oauth_signature = [self.class signClearText:baseString withSecret:secretString];
    allParameters[@"oauth_signature"] = oauth_signature;
    
    NSString *queryString;
    if (queryParameters) queryString = CHQueryStringFromParametersWithEncoding(queryParameters, NSUTF8StringEncoding);
    if (queryString) request_url = [request_url stringByAppendingFormat:@"?%@", queryString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:request_url]];
    request.HTTPMethod = HTTPmethod;
    
    NSMutableArray *parameterPairs = [NSMutableArray array];
    [allParameters removeObjectsForKeys:queryParameters.allKeys];
    for (NSString *name in allParameters) {
        NSString *aPair = [name stringByAppendingFormat:@"=\"%@\"", [allParameters[name] utf8AndURLEncode]];
        [parameterPairs addObject:aPair];
    }
    NSString *oAuthHeader = [@"OAuth " stringByAppendingFormat:@"%@", [parameterPairs componentsJoinedByString:@", "]];
    [request setValue:oAuthHeader forHTTPHeaderField:@"Authorization"];
    if ([HTTPmethod isEqualToString:@"POST"]
        && queryParameters != nil) {
        NSData *body = [queryString dataUsingEncoding:NSUTF8StringEncoding];
        [request setHTTPBody:body];
    }
    
    GLLog(@"request.header:%@", request.allHTTPHeaderFields);
    GLLog(@"request.host:%@", request.HTTPMethod);

    return request;
}


+ (NSString *)URLStringWithoutQueryFromURL:(NSURL *) url
{
    NSArray *parts = [[url absoluteString] componentsSeparatedByString:@"?"];
    return [parts objectAtIndex:0];
}


#pragma mark -
+ (NSString *)signClearText:(NSString *)text withSecret:(NSString *)secret
{
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [text dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[20];
    hmac_sha1((unsigned char *)[clearTextData bytes], [clearTextData length], (unsigned char *)[secretData bytes], [secretData length], result);
    
    //Base64 Encoding
    char base64Result[32];
    size_t theResultLength = 32;
    Base64EncodeData(result, 20, base64Result, &theResultLength);
    NSData *theData = [NSData dataWithBytes:base64Result length:theResultLength];
    
    return [NSString.alloc initWithData:theData encoding:NSUTF8StringEncoding];
}





@end
;