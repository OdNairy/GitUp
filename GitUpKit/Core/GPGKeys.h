#import <Foundation/Foundation.h>
#include <gpgme.h>

NS_ASSUME_NONNULL_BEGIN

@interface GPGKey : NSObject
@property (readonly) NSString* email;
@property (readonly) NSString* name;
@property (readonly) NSString* keyId;

-(NSString*)sign:(NSString*)document clearSigners:(BOOL)clearSigners;

@end

@interface GPGKeys : NSObject
-(instancetype)initWithContext:(gpgme_ctx_t)context;

-(NSArray<GPGKey*>*)allSecretKeys;
@end



NS_ASSUME_NONNULL_END
