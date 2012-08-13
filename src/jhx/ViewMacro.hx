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
					var field:Field;
					
					var templateId = addTemplateResource(meta.params[0]);
					field = createTemplateIdField(templateId);
					fields.push(field);


					if(meta.params.length > 1)
					{
						field = createContainerSelectorField(meta.params[1]);
						fields.push(field);
					}
				}
			}
		}

		return fields;
	}

	static function addTemplateResource(fileExpr : Expr):String
	{
		var file = getFilePath(fileExpr);

		var content = sys.io.File.getContent(file);

		var bytes = haxe.io.Bytes.ofString(content);

		var templateId = META_TEMPLATE + idCount++;

		Context.addResource(templateId, bytes);

		return templateId;

	}

	static function createTemplateIdField(templateId:String):Field
	{
		var field = TPath({ pack : [], name : "String", params : [], sub : null });

		var pos = Context.currentPos();

		var fieldValue : Expr = {
			expr : EConst(CString(templateId)), 
			pos : pos
		};

		return { name : "templateId", doc : null, meta : [], access : [APublic], kind : FVar(field,fieldValue), pos : pos };
	}

	static function createContainerSelectorField(pathExpr:Expr):Field
	{
		var selectorStr = getString(pathExpr);

		var field = TPath({ pack : [], name : "String", params : [], sub : null });

		var pos = Context.currentPos();

		var fieldValue : Expr = {
			expr : EConst(CString(selectorStr)), 
			pos : pos
		};

		return { name : "containerSelector", doc : null, meta : [], access : [APublic], kind : FVar(field,fieldValue), pos : pos };

	}

	// ------------------------------------------------------------------------- common

	static function getFilePath( fileNameExpr : Expr ):String
	{
		var fileStr = getString(fileNameExpr);
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

	static function getString(expr:Expr):String
	{

		var str = null;
		switch( expr.expr )
		{
		case EConst(c):
			switch( c ){
			case CString(s): str = s;
			default:
			}
		default:
		};
		if ( str == null )
			Context.error("Constant string expected",expr.pos);

		return str;
	}
}

#end