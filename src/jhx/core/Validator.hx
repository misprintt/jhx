package jhx.core;

interface Validatable
{
	function validate():Void;
}

class Validator
{
	var valid:Bool;
	var stack:Array<Validatable>;

	public function new():Void
	{
		valid = true;
		stack = [];
	}

	public function invalidate(item:Validatable):Void
	{
		stack.push(item);

		if (valid)
		{
			delayValidation();
			valid = false;
		}
	}

	function delayValidation()
	{
		untyped setTimeout(validate, 1);
	}


	public function validate():Void
	{
		var stackCopy = stack.concat([]);
		while (stackCopy.length > 0)
		{
			var item = stackCopy.shift();
			item.validate();
			stack.remove(item);
		}

		valid = true;
	}
}