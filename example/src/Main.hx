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

		for(i in 0...3)
		{
			var child = new ChildView();
			child.setData(true);
			root.addChild(child);
		}
	}
}


@template("../template/root.html", "ul")
class RootView extends ViewRoot
{
	public var toggled:Bool;
	public function new()
	{
		Reflect.setField(this, "toggled", false);

		super();

		element.click(clickHandler);
	}

	function clickHandler(e)
	{
		set("toggled", !toggled);

		for(child in children)
		{
			var view:ChildView = cast child;
			untyped console.log(view, toggled);
			child.setData(toggled);
		}
	}
}


@template("../template/child.html")
class ChildView extends DataView<Bool>
{
	public function new()
	{
		tagName="li";
		super();
	}
}