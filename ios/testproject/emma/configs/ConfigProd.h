//
//  ConfigProd.h
//  emma
//
//  Created by Ryan Ye on 4/19/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#ifndef emma_ConfigProd_h
#define emma_ConfigProd_h

#undef EMMA_BASE_URL
#define EMMA_BASE_URL @"https://glowing.com"

#undef EMMA_TF_APP_TOKEN
#undef EMMA_TF_SET_DEVICE_UUID

#define EMMA_BUGSENSE_API_KEY @"50b5bb23"

#define DISABLE_NSLOG 1
#define INSTALLED_APPS_KEY @"installed_production_apps"

#define APP_GROUPS @"group.com.glowing.emma"
#define EMMA_URL_SCHEME @"glow"
#define KAYLEE_URL_SCHEME @"kaylee://"

#undef CARDIO_TOKEN 
#define CARDIO_TOKEN @"853990956a3347c5ad986eb67ffe7367"

#undef FUND_DEBUG_SWITCH
#define FUND_DEBUG_SWITCH  0

#undef DEBUG_PANEL_SWITCH
#define DEBUG_PANEL_SWITCH  0

#define MFP_CLIENT_ID @"glow"

#define FITBIT_CONSUMER_KEY         @"44b9df62c4bd41218ab6c09cc0d4cc15"
#define FITBIT_CONSUMER_SECRET      @"fa1d5653a5704db7ae3750519604a979"

#define MISFIT_APP_KEY      @"hZiUscF0UhNQD757"
#define MISFIT_APP_SECRET   @"tMm4w9CvIDpYQHtCA838ZomzQXq0NM1F"
#define MISFIT_REDIRECT_URL_SIGNUP  @"https://glowing.com/misfit/response/signup/ios"
#define MISFIT_REDIRECT_URL_CONNECT @"https://glowing.com/misfit/response/connect/ios"
#define MISFIT_REDIRECT_URL_SIGNIN  @"https://glowing.com/misfit/response/signin/ios"

#undef LOGGING_FLUSH_INTERVAL
#define LOGGING_FLUSH_INTERVAL 20

// Set EMMA_RESTORE_FROM_DATA_SNAPSHOT to a user token to retrieve the debug report of this user from our server
//#define EMMA_RESTORE_FROM_DATA_SNAPSHOT @"jwbFJXOdz0Vse80THeAhVtKXFzi_6xOxC696UcHAVH1C98n-9KuRKCdK6-cj2s7f"

#ifdef PULL_REFERRAL_INTERVAL
    #undef PULL_REFERRAL_INTERVAL
#endif
#define PULL_REFERRAL_INTERVAL (60*60)

#ifdef WALGREENS_GET_LANDING_URL
    #undef WALGREENS_GET_LANDING_URL
#endif
#define WALGREENS_GET_LANDING_URL WALGREENS_GET_LANDING_URL_PROD

#endif
