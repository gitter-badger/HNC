module CPP.Intermediate where

import HN.Intermediate

type CppProgram = [CppDefinition]

data CppDefinition
    =   CppFunctionDef
        {
        	functionLevel			:: Int
		,   functionTemplateArgs	:: [String]
        ,	functionIsStatic		:: Bool
		,  	functionContext			:: Maybe CppContext
        ,	functionReturnType		:: CppType
        ,	functionName        	:: String
        ,   functionArgs    		:: [CppVarDecl]
        ,   functionLocalVars       :: [CppLocalVarDef]
        ,   functionRetExpr         :: CppExpression
        }

data CppExpression
    =   CppApplication CppExpression [CppExpression]
    |   CppAtom String
    |   CppLiteral Const
--    |	CppPtr CppExpression
--    |	CppField CppExpression String

data CppQualifier
	= CppAtomVar				-- a(x), x(a)
	| CppContextVar				-- a(ctx.x), ctx.x(a)
	| CppContextMethod			-- a(hn::bind(ctx, &local::a), ctx.x(a)
	| CppFqConst String			-- a(aaa::bbb::x)
	| CppFqMethod String		-- a(&aaa::bbb::x), aaa::bbb::x(a)
	| CppCurrentClassMethod
	| CppCurrentClassVar
	| CppArgument
	| CppUpperArgument
	| CppLocal
	| CppParentVar
	| CppContextMethodStatic
	| CppCurrentClassMethodStatic
		deriving (Eq, Show)

data CppLocalVarDef
    = CppVar CppType String CppExpression
	| CppWhile CppType String CppExpression CppExpression [CppLocalVarDef] CppExpression

data CppContext
	=	CppContext
		{
			contextLevel 		:: Int
		,	contextTemplateArgs :: [String]
		,	contextTypeName		:: String
		,	contextVars			:: [CppLocalVarDef]
		,	contextMethods		:: CppProgram
		,	contextDeclareSelf	:: Bool
		,	contextParent		:: Maybe String
		}

data CppVarDecl
    =   CppVarDecl CppType String

data CppType
	= CppTypePrimitive String
	| CppTypePolyInstance String [CppType]
	| CppTypeFunction CppType [CppType]
