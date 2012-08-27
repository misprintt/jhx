package ;

import jhx.View;
import jhx.ViewRoot;

import js.JQuery;

class Main
{
	static public function main()
	{

		Console.start();

		var body = new JQuery("body");
		var root = new RootView();

		body.append(root.element);

		for(i in 0...3)
		{
			var child = new ChildView();
			child.setData(false);
			root.addChild(child);
		}
	}
}

@template("../template/root.html", "ul")
class RootView extends ViewRoot
{
	@set var toggled:Bool;
	public function new()
	{
		Reflect.setField(this, "toggled", false);

		super();

		element.click(clickHandler);
	}

	function clickHandler(e)
	{
		toggled = !toggled;

		for(child in children)
		{
			var view:ChildView = cast child;
			trace(view, toggled);
			child.setData(toggled);
		}
	}
}

@template("../template/child.html")
class ChildView extends View<Bool>
{
	public function new()
	{
		tagName="li";
		super();
	}

	override function getTemplateData():Dynamic
	{
		return {
			index:index,
			data: data
		}
	}
}
