package ;

import jhx.View;
import jhx.ViewRoot;

import js.JQuery;

class Main
{
	static public function main()
	{

		var body = new JQuery("body");
		var root = new RootView();

		body.append(root.element);
	}
}


@template("../template/root.html")
class RootView extends ViewRoot
{
	public function new()
	{
		super();
	}
}