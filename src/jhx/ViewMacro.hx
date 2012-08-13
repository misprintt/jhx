package jhx;


#if macro
import haxe.macro.Expr;
import haxe.macro.Context;

/**
* Compiles a template html file as a haxe.Resource and adds a reference to the
* current class in a 'templateId' property
*/
class ViewMacro
{
	static var META_TEMPLATE:String = "template";
	static var idCount:Int = 0;
	
	public static function build() : Array<Field>
	{
		var classType = Context.getLocalClass().get();
		
		var fields = Context.getBuildFields();

		if (classType.meta.has(META_TEMPLATE))
		{
			var metas = classType.meta.get();

			for(meta in metas)
			{
				if (meta.name == META_TEMPLATE)
				{
					var field = addTemplateAndGenerateField(meta.params);
					fields.push(field);
				}
			}
		}

		return fields;
	}

	// static function createClassNameField(className:String):Field
	// {
	// 	var field = TPath({ pack : [], name : "String", params : [], sub : null });

	// 	var fieldValue : Expr = {
	// 		expr : EConst(CString(className)), 
	// 		pos : Context.currentPos()
	// 	};


	// 	return { name : "_className", doc : null, meta : [], access : [APrivate], kind : FVar(field,fieldValue), pos : Context.currentPos() };
	// }

	static function addTemplateAndGenerateField(params : Array<Expr>):Field
	{
		var file = getFilePath(params[0]);

		var content = sys.io.File.getContent(file);

		var bytes = haxe.io.Bytes.ofString(content);

		var templateId = META_TEMPLATE + idCount++;

		Context.addResource(templateId, bytes);

		var field = TPath({ pack : [], name : "String", params : [], sub : null });

		var pos = Context.currentPos();

		var fieldValue : Expr = {
			expr : EConst(CString(templateId)), 
			pos : pos
		};

		return { name : "templateId", doc : null, meta : [], access : [APublic], kind : FVar(field,fieldValue), pos : pos };
	}

	static function getFilePath( fileName : Expr ):String
	{
		var fileStr = null;
		switch( fileName.expr )
		{
		case EConst(c):
			switch( c ){
			case CString(s): fileStr = s;
			default:
			}
		default:
		};
		if ( fileStr == null )
			Context.error("Constant string expected",fileName.pos);

		try
		{
			var file = Context.resolvePath(fileStr);
			return file;
		}
		catch(e:Dynamic)
		{
			Context.error("HTML Template file not found: \"" + fileStr + "\"", Context.currentPos());
		}

		return null;
	}
}

#end