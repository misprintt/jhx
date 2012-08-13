package jhx;

import jhx.View;
import js.JQuery;

class ViewRoot extends View
{
	public function new()
	{
		super();
	}

	override function initialize()
	{
		super.initialize();
		container = new JQuery("body");
	}
}