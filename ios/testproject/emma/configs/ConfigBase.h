//
//  cfg_all.h
//  emma
//
//  Created by Ryan Ye on 2/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#ifndef emma_cfg_all_h
#define emma_cfg_all_h

#define EMMA_BASE_URL @"http://localhost:8080"

#define EMMA_DATA_STORE_TYPE NSSQLiteStoreType
#define EMMA_DATA_STORE_FILENAME @"test.db"

#define EMMA_FB_PERMISSIONS @[@"user_birthday", @"user_relationships", @"email"]

#define EMMA_NOTIFICATION_WATERMARK_LIMIT 150
#define EMMA_NOTIFICATION_ALARM_DAYS 6

#define EMMA_REMINDERS_LIMIT 100

#define NETWORK_TIMEOUT_INTERVAL 20.0
#define NETWORK_PAYMENT_TIMEOUT  90.0
#define NETWORK_MULTIPART_TIMEOUT  90.0

#define EMMA_DISABLE_TUTORIAL 0

#define EMMA_ALLOW_FUTURE_LOG NO

#define EMMA_DISABLE_LOG NO

#define PUSH_PREDICTION NO

#define FACEBOOK_URL @"https://www.facebook.com/glow"
#define TWITTER_URL @"https://twitter.com/glowHQ"
#define BLOG_URL @"http://blog.glowing.com"

#define THE_WEB_URL @"/home?inapp=1"
#define TOS_URL @"/tos?inapp=1"
#define FUND_TOS_URL @"/fund_tos?inapp=1"
#define PRIVACY_POLICY_URL @"/privacy?inapp=1"
#define FAQ_URL @"/faq?inapp=1"
#define SUCCESS_STORIES_URL @"/stories?inapp=1"
#define GLOW_BLOG_URL @"/blog?inapp=1"
#define FUND_PARTNER_COMPANIES_URL @"/glow_first/partners?inapp=1"
#define INSIGHT_PAGE_URL @"/insight"
#define REFERRAL_INTRO_URL @"/refer/intro?inapp=1"
#define TERMS_OF_PAYMENT_URL @"/terms_of_payment?inapp=1"

#define DOWNLOAD_APP_URL @"http://itunes.apple.com/us/app/id638021335"
#define DOWNLOAD_PREGNANCY_APP_URL @"http://itunes.apple.com/us/app/id882398397"

// Errors
#define ERROR_DOMAIN_NETWORK @"network"

#define ERROR_CODE_BAD_REQUEST 400
#define ERROR_CODE_SERVER_ERROR 500
#define ERROR_CODE_SERVICE_UNAVAILBLE 503
#define ERROR_CODE_NOT_FOUND 404
#define ERROR_CODE_UNKNOWN_NEWORK_ERROR 999

#define ERROR_DOMAIN_USER @"user"

#define ERROR_CODE_CANNOT_INVITE_PARTNER 100

#define APP_ID @"638021335"
#define RUBY_APP_ID @"1002275138"

#define LAUNCH_TIMES_BEFORE_RATE  5
#define USED_DAYS_BEFORE_RATE     10
#define REMIND_RATE_DELAY  (7 * 86400)

#define DAYS_BEFORE_ASKING_FOR_SHARE 2
#define DAYS_BEFORE_ASKING_FOR_INVITE 3
#define DAYS_BEFORE_ASKING_SHARE_STORY 7

// delay 3 days if user choose cancel upgrade
#define DELAY_REMIND_TIME  (3 * 24 * 3600)

#define FEEDBACK_RECEIVER @"support@glowing.com"
#define GF_CLAIM_RECEIVER @"claims@glowing.com"

#define APP_ACTIVE_TIMEOUT  60 * 1
#define MIN_PASSWORD_LENGTH 6
#define VERIFICATION_CODE_LENGTH 6

// #define APP_NAME [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey]
#define CARDIO_TOKEN @"74a42234815647aabaea87080eb4c181"

//test token from Eric's account.

#define URL_HOST_RESET_PASSWORD @"reset_password"
#define URL_HOST_FORUM_TOPIC @"forum_topic"
#define URL_HOST_FORUM_CATEGORY @"forum_category"
#define URL_HOST_FORUM_GROUP @"forum_group"

#define FUND_DEBUG_SWITCH  0
#define DEBUG_PANEL_SWITCH  0
#define ENABLE_GF_ENTERPRISE 1

#define MAX_GENERAL_INSIGHT_PRI 99

#define APP_OPEN_WITH_OPTION @"appOpenWithOption"
#define APP_OPEN_EXT_DATA @"appOpenExtData"
#define APP_OPEN_TYPE_NONE     0
#define APP_OPEN_TYPE_LOG     11
#define APP_OPEN_TYPE_GENIUS  12
#define APP_OPEN_TYPE_FUND    13
#define APP_OPEN_TYPE_LOG_BBT 14
#define APP_OPEN_TYPE_FORUM_TOPIC 15
#define APP_OPEN_TYPE_FORUM_REPLY 16
#define APP_OPEN_TYPE_URL     17
#define APP_OPEN_TYPE_PERIOD   18
#define APP_OPEN_TYPE_ALERT   19
#define APP_OPEN_TYPE_FORUM_PROFILE 20

#define PERIOD_LENGTH_MIN 3
#define PERIOD_LENGTH_MAX 9
#define PERIOD_LENGTH_DEFAULT 5

#define CYCLE_LENGTH_MIN 22
#define CYCLE_LENGTH_MAX 90
#define CYCLE_LENGTH_DEFAULT 28

#define TIPS_LIST @[]
#define TIPS_URL @"/term"
#define DETECT_TIPS YES

//Js interpreter config
// RULES_INTERPRETER: value can be Interpreter or JsInterpreter
//     Interpreter uses a webview to run js, while JsInterpreter uses JavaScriptCore to interpreter directly.
// PREDICTION_IN_SUBQUEUE: set to zero the prediction rules will be run in main queue, while the rules run in subqueue if set to other value.
//     Notice that if RULES_INTERPRTER is set Interpreter the prediction rules will ALWAYS be run in main queue.
#define RULES_INTERPRETER JsInterpreter
#define PREDICTION_IN_SUBQUEUE 0

#define WEB_TOKEN_COOKIE_NAME @"GLOW_WEB_ACCESS_TOKEN"
#define WEB_ACCESS_TOKEN @""

#define JAWBONE_APP_ID @"0Cze7CibsIA"
#define JAWBONE_APP_SECRET @"2959eeb71f5b9cf9b28e6b814f8012d3"

#define CLEAR_CACHE_ON_LAUNCH @"clear_cache_on_launch"

#define LOGGING_FLUSH_INTERVAL 10

#define MAX_AGE (60 * ((int)(60*60*24*365.2425)))
#define MIN_AGE (13 * ((int)(60*60*24*365.2425)))
#define DEFAULT_AGE (30 * ((int)(60*60*24*365.2425)))

#define PULL_REFERRAL_INTERVAL (60*60*23)

#define FORCE_SHOW_GG_TUTORIAL 0

// walgreens
#define WALGREENS_API_KEY @"7Os7JViGl4SozT3sdBs68ICul7yAoCZI"
#define WALGREENS_API_AFF_ID @"glow"

#define WALGREENS_GET_LANDING_URL_PROD @"https://services.walgreens.com/api/util/mweb5url"
#define WALGREENS_GET_LANDING_URL_SANDBOX @"https://services-qa.walgreens.com/api/util/mweb5url"

#define WALGREENS_GET_LANDING_URL WALGREENS_GET_LANDING_URL_SANDBOX
#define WALGREENS_BACK_TO_GLOW_DELAY 180

#endif
