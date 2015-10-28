//
//  Tooltip.m
//  emma
//
//  Created by Eric Xu on 10/14/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "Tooltip.h"
#import "GLDialogViewController.h"
#import "User.h"


@interface TooltipDialog: UIViewController <UIAlertViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic, strong) GLDialogViewController *dialog;
@property (strong, nonatomic) IBOutlet UILabel *keywordLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;

- (void)presentWithKeyword:(NSString *)keyword;

@end

@implementation TooltipDialog

- (void)awakeFromNib
{
    self.dialog = [GLDialogViewController sharedInstance];
}

- (void)presentWithKeyword:(NSString *)keyword
{
    if(!self.dialog) {
        self.dialog = [GLDialogViewController sharedInstance];
    }
        
    [self.dialog presentWithContentController:self];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[Utils makeUrl:TIPS_URL query:@{@"keyword": keyword}]] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10]];
//    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[Utils makeUrl:TIPS_URL query:@{@"keyword": keyword}]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10]];
    [self.keywordLabel setText:keyword];
    
    @weakify(self)
    [self subscribe:EVENT_DIALOG_CLOSE_BUTTON_CLICKED handler:^(Event *event) {
        @strongify(self)
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        [self.keywordLabel setText:@""];
    }];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    GLLog(@"webViewDidFinishLoad:%@", webView.request);
    [self.loadingIndicator stopAnimating];
    self.loadingIndicator.hidden = YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    GLLog(@"webViewFailedLoad:%@", error);
    [self.loadingIndicator stopAnimating];
    self.loadingIndicator.hidden = YES;
    [[[UIAlertView alloc] initWithTitle:nil message:@"Could not connect to the server" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    GLLog(@"webViewDidStartLoad:%@", webView.request);
    self.loadingIndicator.hidden = NO;
    [self.loadingIndicator startAnimating];
    
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self.dialog close];
}
@end

@implementation Tooltip

+ (void)tip:(NSString *)tip
{
    static TooltipDialog *tooltipDialog;
    if (!tooltipDialog) {
        tooltipDialog = [[TooltipDialog alloc] initWithNibName:@"TooltipDialog" bundle:nil];
    }
    GLLog(@"tip: %@", tip);
    
    [tooltipDialog presentWithKeyword:tip];
}

+ (NSArray *)keywords
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
 
    NSArray *saved = [defaults stringArrayForKey:USER_DEFAULTS_KEYWORDS];
    if (saved && [saved count] > 0) {
        return saved;
    } else
        return TIPS_LIST;
}

+ (NSArray *)keywordsOrderByLength
{
    NSMutableArray *keywords = [[self keywords] mutableCopy];
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"length" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    [keywords sortUsingDescriptors:sortDescriptors];
    return keywords;
}

+ (void)updateKeywords:(NSArray *)newKeywords
{
    if (newKeywords && [newKeywords count] > 0) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:newKeywords forKey:USER_DEFAULTS_KEYWORDS];
        [defaults synchronize];
    }
    
}

+ (void)setCallbackForAllKeywordOnLabel:(UILinkLabel *)label {
    [self setCallbackForAllKeywordOnLabel:label caseSensitive:YES];
}

+ (void)setCallbackForAllKeywordOnLabel:(UILinkLabel *)label caseSensitive:(BOOL)caseSensitive
{
    [label clearCallbacks];
    for (NSString *kw in [Tooltip keywords]) {
        [label setCallback:^(NSString *str) {[Tooltip tip:str];}
                forKeyword:kw caseSensitive:caseSensitive];
    }
}

+ (NSString *)replaceTermLinksInHtml:(NSString *)html caseSensitive:(BOOL)caseSensitive
{
    NSRegularExpressionOptions options = NSRegularExpressionUseUnicodeWordBoundaries;
    if (!caseSensitive) {
        options |= NSRegularExpressionCaseInsensitive;
    }
    NSString *template = [NSString stringWithFormat:@"<a href=\"%@://$0\">$0</a>", SCHEME_TOOLTIP];
    NSString *keyword = [[Tooltip keywordsOrderByLength] componentsJoinedByString:@"|"];
    GLLog(@"Replacing %@", keyword);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\b(%@)\\b", keyword]
                                                                           options:options
                                                                             error:nil];
    
    html = [regex stringByReplacingMatchesInString:html options:0 range:NSMakeRange(0, [html length]) withTemplate:template];
    return html;
}

@end
