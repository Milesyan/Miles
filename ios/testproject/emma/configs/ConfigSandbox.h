//
//  ConfigSandbox.h
//  emma
//
//  Created by Ryan Ye on 3/26/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#ifndef emma_ConfigSandbox_h
#define emma_ConfigSandbox_h

#define EMMA_TF_APP_TOKEN @"b7936cd5-47c6-477d-b17e-b7c2e423cbe6"
#define EMMA_TF_SET_DEVICE_UUID 1

#define EMMA_BUGSENSE_API_KEY @"cc2f60f9"

#undef EMMA_BASE_URL
#define EMMA_BASE_URL @"https://dragon-emma.glowing.com"
//#define EMMA_BASE_URL @"https://golem-emma.glowing.com"

#define DISABLE_NSLOG 1

#define APP_GROUPS @"group.com.glowing.emmabeta"
#define EMMA_URL_SCHEME @"glowsandbox"
#define KAYLEE_URL_SCHEME @"kayleebeta://"
#define INSTALLED_APPS_KEY @"installed_sandbox_apps"

#undef CARDIO_TOKEN
#define CARDIO_TOKEN @"7be567fc622441b5a1c0f00d5af4b9f1"

#undef FUND_DEBUG_SWITCH
#define FUND_DEBUG_SWITCH  1

#undef DEBUG_PANEL_SWITCH
#define DEBUG_PANEL_SWITCH  0

#undef ENABLE_GF_ENTERPRISE
#define ENABLE_GF_ENTERPRISE  1

#define MFP_CLIENT_ID @"glow"

#undef WEB_ACCESS_TOKEN 
#define WEB_ACCESS_TOKEN @"jxTlrMrDC^eynV*#*}tf^x64vMj7qS&^"

#define FITBIT_CONSUMER_KEY         @"15a2a4fefe294a50bbf2f2ac9de3ef32"
#define FITBIT_CONSUMER_SECRET      @"115c740c4d6d4ab09be0e5b08ee11c4b"

#ifdef PULL_REFERRAL_INTERVAL
    #undef PULL_REFERRAL_INTERVAL
#endif
#define PULL_REFERRAL_INTERVAL 1

#define MISFIT_APP_KEY      @"SZW2CyLjSKsLvS87"
#define MISFIT_APP_SECRET   @"uNJZRzC7CyNelDVW2vfaDwYWlcY8jvAt"
#define MISFIT_REDIRECT_URL_SIGNUP  @"https://dragon-emma.glowing.com/misfit/response/signup/ios"
#define MISFIT_REDIRECT_URL_CONNECT @"https://dragon-emma.glowing.com/misfit/response/connect/ios"
#define MISFIT_REDIRECT_URL_SIGNIN  @"https://dragon-emma.glowing.com/misfit/response/signin/ios"

#ifdef WALGREENS_BACK_TO_GLOW_DELAY
    #undef WALGREENS_BACK_TO_GLOW_DELAY
#endif
#define WALGREENS_BACK_TO_GLOW_DELAY 60

#endif
