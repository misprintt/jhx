package jhx;

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
		while (stack.length > 0)
		{
			var item = stack.shift();
			item.validate();
		}

		valid = true;
	}
}