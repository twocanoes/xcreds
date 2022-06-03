//
//  SecurityPrivateAPI.h
//  NoMAD
//
//  Created by Phillip Boushy on 4/26/16.
//  Copyright © 2016 Trusource Labs. All rights reserved.
//

#ifndef SecurityPrivateAPI_h
#define SecurityPrivateAPI_h

// So we can use SecKeychainChangePassword() in NoMADUser
#import <Security/Security.h>
extern OSStatus SecKeychainChangePassword(SecKeychainRef keychainRef, UInt32 oldPasswordLength, const void* oldPassword, UInt32 newPasswordLength, const void* newPassword);

#endif /* SecurityPrivateAPI_h */
