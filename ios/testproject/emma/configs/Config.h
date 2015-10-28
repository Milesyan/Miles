//
//  configs.h
//  emma
//
//  Created by Ryan Ye on 2/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#ifndef emma_configs_h
#define emma_configs_h

#include "ConfigBase.h"

#ifdef TARGET_DEV
#include "ConfigDev.h"
#include "ConfigLocal.h"
#endif 

#ifdef TARGET_TEST
#include "ConfigTest.h"
#include "ConfigLocal.h"
#endif

#ifdef TARGET_SANDBOX
#include "ConfigSandbox.h"
#endif

#ifdef TARGET_PROD   
#include "ConfigProd.h"
#endif

#endif
