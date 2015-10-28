//
//  cfg_test.h
//  emma
//
//  Created by Ryan Ye on 2/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#ifndef emma_cfg_test_h
#define emma_cfg_test_h

// Data Store
#undef EMMA_DATA_STORE_TYPE
#define EMMA_DATA_STORE_TYPE NSInMemoryStoreType

#undef NETWORK_TIMEOUT_INTERVAL
#define NETWORK_TIMEOUT_INTERVAL 2.0
#endif
