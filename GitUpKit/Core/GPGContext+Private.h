//
//  GPGContext+GPGContext_Private.h
//  GitUpKit
//
//  Created by Roman Gardukevich on 18/10/2018.
//

#import "GPGContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface GPGContext()
@property (nonatomic, assign) gpgme_ctx_t gpgContext;
@end

NS_ASSUME_NONNULL_END
