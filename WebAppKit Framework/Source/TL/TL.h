#import "TLStatement.h"
#import "TLExpression.h"
#import "TLScope.h"

#import "TLCompoundStatement.h"
#import "TLForeachLoop.h"
#import "TLWhileLoop.h"
#import "TLConditional.h"
#import "TLAssignment.h"

#import "TLObject.h"
#import "TLIdentifier.h"
#import "TLOperation.h"
#import "TLMethodInvocation.h"

NSString *const TLParseException;
NSString *const TLRuntimeException;