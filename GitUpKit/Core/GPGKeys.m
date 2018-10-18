#import "GPGKeys.h"


@interface GPGKey()
@property (nonatomic, assign) gpgme_key_t key;
@property (nonatomic, assign) gpgme_ctx_t gpgContext;
@property (nonatomic, strong, nullable) NSString* name;
@property (nonatomic, strong, nullable) NSString* email;
@property (nonatomic, strong, nullable) NSString* keyId;

@end


NSString* helperGpgDataToString(gpgme_data_t data) {
    gpgme_data_seek(data, 0, SEEK_SET);
    char buffer[1024] = {0};
    ssize_t readCount = gpgme_data_read(data, buffer, 1024);
    
    NSData* readData = [[NSData alloc] initWithBytes:buffer length:readCount];
    NSString* readString = [[NSString alloc] initWithData:readData encoding:NSUTF8StringEncoding];
    
    return readString;
}

@implementation GPGKey

- (instancetype)initWithGPGKey:(gpgme_key_t)key context:(gpgme_ctx_t)gpgContext {
    self = [super init];
    if (self) {
        self.key = key;
        self.gpgContext = gpgContext;
        
        if (_key->uids) {
            if (_key->uids->name) {
                _name = [[NSString alloc] initWithCString:_key->uids->name
                                                 encoding:NSUTF8StringEncoding];
            }
            if (_key->uids->email) {
                _email = [[NSString alloc] initWithCString:_key->uids->email
                                                  encoding:NSUTF8StringEncoding];
            }
        }
        
        if (_key->subkeys) {
            if (_key->subkeys->keyid) {
                _keyId = [[NSString alloc] initWithCString:_key->subkeys->keyid
                                                  encoding:NSUTF8StringEncoding];
            }
        }
    }
    return self;
}

-(NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p 'keyId: %@' 'email: %@' 'name: %@'>", self.class, self, self.keyId, self.email, self.name];
}

-(void)dealloc {
    gpgme_key_unref(_key);
}

-(NSString*)sign:(NSString*)document clearSigners:(BOOL)clearSigners {
    if (clearSigners) {
        gpgme_signers_clear(_gpgContext);
    }
    gpgme_signers_add(_gpgContext, _key);
    
    gpgme_data_t in, out;
    gpgme_data_new(&out);
    
    const char* s = [document UTF8String];
    NSUInteger count = document.length;
    gpgme_error_t err = gpgme_data_new_from_mem(&in, s, count, 0);
    if (err) {
        printf("%s\n", gpg_strerror(err));
    }
    
    gpgme_set_textmode(_gpgContext, 0);
    gpgme_set_armor(_gpgContext, 1);
    
    err = gpgme_op_sign(_gpgContext, in, out, GPGME_SIG_MODE_DETACH);
    if (err) {
        printf("%s\n", gpg_strerror(err));
    }
    
    NSString* signatureString = helperGpgDataToString(out);
    
    return signatureString;
}

@end



@interface GPGKeys ()
@property (nonatomic, assign, nonnull) gpgme_ctx_t gpgContext;
@property (nonatomic, assign) BOOL shouldReleaseContext;
@end

@implementation GPGKeys

+(void)initialize {
    gpgme_check_version(NULL);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        gpgme_error_t initError = gpgme_new(&_gpgContext);
        _shouldReleaseContext = YES;
        if (initError) {
            printf("Error during initialization: %s", gpgme_strerror(initError));
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithContext:(gpgme_ctx_t)context {
    self = [super init];
    if (self) {
        self.gpgContext = context;
        _shouldReleaseContext = NO;
    }
    return self;
}

-(NSArray<GPGKey *> *)allSecretKeys {
    gpgme_key_t key;
    gpg_error_t err = gpgme_op_keylist_start (_gpgContext, NULL, 1);
    
    NSMutableArray<GPGKey*> *keys = [NSMutableArray array];
    while (!err)
    {
        err = gpgme_op_keylist_next (_gpgContext, &key);
        if (err)
            break;
//        printf ("%s:", key->subkeys->keyid);
//        if (key->uids && key->uids->name)
//            printf (" %s", key->uids->name);
//        if (key->uids && key->uids->email)
//            printf (" <%s>", key->uids->email);
        
        GPGKey* gpgKey = [[GPGKey alloc] initWithGPGKey:key context:_gpgContext];
        [keys addObject:gpgKey];
        putchar ('\n');
    }
    
    if (gpg_err_code (err) != GPG_ERR_EOF)
    {
        fprintf (stderr, "can not list keys: %s\n", gpgme_strerror (err));
        exit (1);
    }
    
    return [keys copy];
}

-(void)dealloc {
    if (_shouldReleaseContext) {
        gpgme_release(_gpgContext);
    }
}

@end



void listPrivateKeys() {
    gpgme_ctx_t ctx;
    gpgme_key_t key;
    gpgme_error_t err = gpgme_new (&ctx);
    
    if (!err)
    {
        err = gpgme_op_keylist_start (ctx, NULL, 1);
        while (!err)
        {
            err = gpgme_op_keylist_next (ctx, &key);
            if (err)
                break;
            printf ("%s:", key->subkeys->keyid);
            if (key->uids && key->uids->name)
                printf (" %s", key->uids->name);
            if (key->uids && key->uids->email)
                printf (" <%s>", key->uids->email);
            putchar ('\n');
            gpgme_key_release (key);
        }
        gpgme_release (ctx);
    }
    if (gpg_err_code (err) != GPG_ERR_EOF)
    {
        fprintf (stderr, "can not list keys: %s\n", gpgme_strerror (err));
        exit (1);
    }
    
}
