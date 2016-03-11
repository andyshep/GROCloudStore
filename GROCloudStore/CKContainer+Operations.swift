//
//  CKContainer+Operations.swift
//  GROCloudStore
//

/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.

Abstract:
A convenient extension to CloudKit.CKContainer.

Sample code project: Advanced NSOperations
Version: 1.0

IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

*/

import CloudKit

public extension CKContainer {
    /**
     Verify that the current user has certain permissions for the `CKContainer`,
     and potentially requesting the permission if necessary.
     
     - parameter permission: The permissions to be verified on the container.
     
     - parameter shouldRequest: If this value is `true` and the user does not
     have the passed `permission`, then the user will be prompted for it.
     
     - parameter completion: A closure that will be executed after verification
     completes. The `NSError` passed in to the closure is the result of either
     retrieving the account status, or requesting permission, if either
     operation fails. If the verification was successful, this value will
     be `nil`.
     */
    public func verifyPermission(permission: CKApplicationPermissions, requestingIfNecessary shouldRequest: Bool = false, completion: NSError? -> Void) {
        verifyAccountStatus(self, permission: permission, shouldRequest: shouldRequest, completion: completion)
    }
}

/**
 Make these helper functions instead of helper methods, so we don't pollute
 `CKContainer`.
 */
private func verifyAccountStatus(container: CKContainer, permission: CKApplicationPermissions, shouldRequest: Bool, completion: NSError? -> Void) {
    container.accountStatusWithCompletionHandler { accountStatus, accountError in
        if accountStatus == .Available {
            if permission != [] {
                verifyPermission(container, permission: permission, shouldRequest: shouldRequest, completion: completion)
            }
            else {
                completion(nil)
            }
        }
        else {
            let error = accountError ?? NSError(domain: CKErrorDomain, code: CKErrorCode.NotAuthenticated.rawValue, userInfo: nil)
            completion(error)
        }
    }
}

private func verifyPermission(container: CKContainer, permission: CKApplicationPermissions, shouldRequest: Bool, completion: NSError? -> Void) {
    container.statusForApplicationPermission(permission) { permissionStatus, permissionError in
        if permissionStatus == .Granted {
            completion(nil)
        }
        else if permissionStatus == .InitialState && shouldRequest {
            requestPermission(container, permission: permission, completion: completion)
        }
        else {
            let error = permissionError ?? NSError(domain: CKErrorDomain, code: CKErrorCode.PermissionFailure.rawValue, userInfo: nil)
            completion(error)
        }
    }
}

private func requestPermission(container: CKContainer, permission: CKApplicationPermissions, completion: NSError? -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        container.requestApplicationPermission(permission) { requestStatus, requestError in
            if requestStatus == .Granted {
                completion(nil)
            }
            else {
                let error = requestError ?? NSError(domain: CKErrorDomain, code: CKErrorCode.PermissionFailure.rawValue, userInfo: nil)
                completion(error)
            }
        }
    }
}
