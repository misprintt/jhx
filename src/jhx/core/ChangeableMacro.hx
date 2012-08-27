package jhx.core;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

class ChangeableMacro
{
	static var META_SET:String = "set";
	static var META_GET:String = "get";
	static var fields:Array<Field>;


	static public function build():Array<Field>
	{
		var cls = Context.getLocalClass().get();

		fields = Context.getBuildFields();

		var tempFields = fields.concat([]);

		for(field in tempFields)
		{
			switch(field.kind)
			{
				case FVar(t, e):  parseVar(field, t, e);
				case FProp(get, set, t, e):
				case FFun(f):
			}
		}

		return fields;
	}

	static function parseVar(field:Field, t:ComplexType, ?e:Expr)
	{
		var setMeta:{ pos : Position, params : Array<Expr>, name : String } = null;
		var getMeta:{ pos : Position, params : Array<Expr>, name : String } = null;

		for(m in field.meta)
		{
			if(m.name == META_SET)
			{
				setMeta = m;
				continue;
			}
			else if (m.name == META_GET)
			{
				getMeta = m;
				continue;
			}
		}

		if(setMeta == null) return;

		if(getMeta != null)
		{
			field.kind = FProp("get_" + field.name, "set_" + field.name, t, e);
		}
		else
		{
			field.kind = FProp("default", "set_" + field.name, t, e);	
		}
		
		field.access = [APublic];
		field.meta = [];

		//add getter

		var getter = createGetter(field.name, t);

		fields.push(getter);

		var setter = createSetter(field.name, t);
		fields.push(setter);
	}

	static function createGetter(name:String, t:ComplexType):Field
	{
		var eProp : Expr = 
		{
			expr : EConst(CIdent(name)), 
			pos : Context.currentPos()
		};

		var eReturn : Expr = 
		{
			expr : EReturn(eProp),
			pos : Context.currentPos()
		};

		var expr:Expr =
		{
			expr : EBlock([eReturn]),
			pos : Context.currentPos()
		};

		var func:Function =
		{
			ret:t,
			params:[],
			expr:expr,
			args:[]
		};

		var field:Field = 
		{
			pos:Context.currentPos(),
			name:"get_" + name,
			meta:[],
			kind:FFun(func),
			access:[]
		};

		return field;

	}


	static function createSetter(name:String, t:ComplexType):Field
	{

		var ePropName : Expr = 
		{
			expr : EConst(CString(name)), 
			pos : Context.currentPos()
		};

		var eValue : Expr = 
		{
			expr : EConst(CIdent("value")), 
			pos : Context.currentPos()
		};

		var eFunc : Expr = 
		{
			expr: EConst(CIdent("set")),
			pos: Context.currentPos()
		};

		var eCall : Expr = 
		{
			expr : ECall(eFunc, [ePropName, eValue]),
			pos : Context.currentPos()
		};

		var eProp :Expr = 
		{
			expr : EConst(CIdent(name)), 
			pos : Context.currentPos()
		};

		var ePropAssign : Expr = 
		{
			expr: EBinop(OpAssign, eProp, eCall),
			pos : Context.currentPos()
		}

		var eReturn : Expr = 
		{
			expr : EReturn(eProp),
			pos : Context.currentPos()
		};


		var expr:Expr =
		{
			expr : EBlock([ePropAssign, eReturn]),
			pos : Context.currentPos()
		} ;

		var arg:FunctionArg =
		{
			name:"value",
			opt:false,
			type:t,
			value:null
		};

		var func:Function =
		{
			ret:t,
			params:[],
			expr:expr,
			args:[arg]
		};

		var field:Field = 
		{
			pos:Context.currentPos(),
			name:"set_" + name,
			meta:[],
			kind:FFun(func),
			access:[]
		};

		return field;

	}
}

#end