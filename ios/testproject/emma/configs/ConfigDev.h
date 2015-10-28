//
//  ConfigDev.h
//  emma
//
//  Created by Ryan Ye on 2/8/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#ifndef emma_ConfigDev_h
#define emma_ConfigDev_h

#undef NETWORK_TIMEOUT_INTERVAL
#define NETWORK_TIMEOUT_INTERVAL 5.0

#define APP_GROUPS @"group.com.glowing.emmadev"
#define EMMA_URL_SCHEME @"glowdev"
#define KAYLEE_URL_SCHEME @"kayleedev://"
#define INSTALLED_APPS_KEY @"installed_dev_apps"

#define MFP_CLIENT_ID @"glow"

#define FITBIT_CONSUMER_KEY         @"15a2a4fefe294a50bbf2f2ac9de3ef32"
#define FITBIT_CONSUMER_SECRET      @"115c740c4d6d4ab09be0e5b08ee11c4b"

#define MISFIT_APP_KEY      @"xRSjN2nOHTzvqHD7"
#define MISFIT_APP_SECRET   @"McgYXuCGPQClPzEbFdHYA5GGb5bxBGn2"
#define MISFIT_REDIRECT_URL_SIGNUP @"http://127.0.0.1:8080/misfit/response/signup/ios"
#define MISFIT_REDIRECT_URL_CONNECT @"http://127.0.0.1:8080/misfit/response/connect/ios"
#define MISFIT_REDIRECT_URL_SIGNIN @"http://127.0.0.1:8080/misfit/response/signin/ios"

#ifdef PULL_REFERRAL_INTERVAL
    #undef PULL_REFERRAL_INTERVAL
#endif
#define PULL_REFERRAL_INTERVAL (60)

#ifdef WALGREENS_BACK_TO_GLOW_DELAY
    #undef WALGREENS_BACK_TO_GLOW_DELAY
#endif
#define WALGREENS_BACK_TO_GLOW_DELAY 20

#endif
