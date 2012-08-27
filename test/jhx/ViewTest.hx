package jhx;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import jhx.View;
import jhx.core.Changeable;
import js.JQuery;
import js.Lib;
import js.Dom;

/**
* Auto generated MassiveUnit Test Class  for jhx.View 
*/
class ViewTest 
{
	var instance:MockView; 
	var data:MockData;

	var changed:Bool;
	var changedValues:Array<String>;

	var childInstance:MockView;


	var addedCount:Int;
	var removedCount:Int;


	var temp:HtmlDom;

	public function new() 
	{
		
	}
	
	@BeforeClass
	public function beforeClass():Void
	{
	}
	
	@AfterClass
	public function afterClass():Void
	{
	}
	
	@Before
	public function setup():Void
	{
		data = new MockData();
		changedValues = [];
		changed = false;
		addedCount = 0;
		removedCount = 0;

		temp = Lib.document.createElement("div");
		 Lib.document.body.appendChild(temp);
	}
	
	@After
	public function tearDown():Void
	{
		 Lib.document.body.removeChild(temp);
	}

	//-------------------------------------------------------------------------- constructor
	
	@Test
	public function constructor_with_zero_args_creates_div():Void
	{
		instance = new MockView();

		Assert.isNotNull(instance.element);

		Assert.isNull(instance.data);

		Assert.isTrue(instance.element.is("div"));

		Assert.isTrue(instance.element.hasClass("MockView"));
	}

	@Test
	public function constructor_with_data():Void
	{
		instance = new MockView(data);
		Assert.areEqual(data, instance.data);
	}

	@Test
	public function constructor_with_element_inherits_id():Void
	{
		var id = "test";
	
		var element = new JQuery(js.Lib.document.createElement("div"));
		element.attr("id", id);

		instance = new MockView(null, element);

		Assert.areEqual(element, instance.element);
		Assert.isTrue(instance.element.hasClass("MockView"));
		Assert.areEqual(id, instance.id);
	}

	//-------------------------------------------------------------------------- data
	
	@AsyncTest
	public function should_dispatch_data_changed(factory:AsyncFactory):Void
	{
		var handler:Dynamic = factory.createHandler(this, dataChangedHandler, 300);

		instance = new MockView();
		instance.on("data", handler);
		instance.setData(data);
	}

	function dataChangedHandler(event)
	{
		changed = true;
		changedValues.push("data");
		Assert.areEqual(MockView, Type.getClass(event.target));
		Assert.areEqual("data", event.type);
	}

	@AsyncTest
	public function should_not_dispatch_data_changed_if_same_data(factory:AsyncFactory):Void
	{
		var handler:Dynamic = factory.createHandler(this, assertDataNotChanged, 300);

		instance = new MockView();
		instance.setData(data);

		instance.validate();

		instance.on("data", dataChangedHandler);

		instance.setData(data);

		Timer.delay(handler,200);
	}

	@AsyncTest
	public function should_dispatch_data_changed_if_forced(factory:AsyncFactory):Void
	{
		var handler:Dynamic = factory.createHandler(this, dataChangedHandler, 300);

		instance = new MockView();
		instance.setData(data);

		instance.validate();

		instance.on("data", handler);

		instance.setData(data, true);
	}

	// //-------------------------------------------------------------------------- add child
	
	@Test
	public function should_set_parent_on_addChild():Void
	{
		instance = new MockView();

		childInstance = new MockView();
		instance.addChild(childInstance);

		Assert.areEqual(instance, childInstance.parent);
		Assert.areEqual(0, childInstance.index);
	}

	@AsyncTest
	public function should_dispatch_added_on_addChild(factory:AsyncFactory):Void
	{
		var handler:Dynamic = factory.createHandler(this, addedHandler, 300);
		
		instance = new MockView();
		instance.on("added", handler);

		childInstance = new MockView();
		instance.addChild(childInstance);
	}

	function addedHandler(event)
	{
		addedCount ++;
		Assert.areEqual(childInstance,event.target);
		Assert.areEqual("added", event.type);
	}


	@AsyncTest
	public function should_remove_from_existing_parent_on_addChild(factory:AsyncFactory):Void
	{
		var handler:Dynamic = factory.createHandler(this, removedHandler, 300);

		instance = new MockView();

		childInstance = new MockView();
		instance.addChild(childInstance);
		instance.on("removed", handler);

		var instance2 = new MockView();

		instance2.addChild(childInstance);

		Assert.areEqual(instance2, childInstance.parent);
		Assert.areEqual(0, childInstance.index);
	}

	function removedHandler(event)
	{
		removedCount ++;
		Assert.areEqual(childInstance,event.target);
		Assert.areEqual("removed", event.type);
	}

	@Test
	public function should_throw_exception_adding_to_self():Void
	{
		var exceptionThrown = false;
		try
		{
			instance = new MockView();
			instance.addChild(instance);
		}
		catch(e:Dynamic)
		{
			exceptionThrown =true;
		}

		Assert.isTrue(exceptionThrown);
	}

	@Test
	public function should_throw_exception_if_adding_existing_child():Void
	{
		var exceptionThrown = false;
		try
		{
			instance = new MockView();
			childInstance = new MockView();
			instance.addChild(childInstance);
			instance.addChild(childInstance);
		}
		catch(e:Dynamic)
		{
			exceptionThrown =true;
		}

		Assert.isTrue(exceptionThrown);
	}
	

	@AsyncTest
	public function should_dispatch_added_for_all_descendants(factory:AsyncFactory):Void
	{
		var handler:Dynamic = factory.createHandler(this, assertAddedCount, 300);
		
		instance = new MockView();
		instance.on("added", addedViewHandler);

		childInstance = new MockView();
		var grandChildInstance = new MockView();

		childInstance.addChild(grandChildInstance);
		instance.addChild(childInstance);

		Timer.delay(handler, 200);
	}

	function addedViewHandler(event)
	{
		addedCount ++;
	}

	// //-------------------------------------------------------------------------- remove child
	
	@Test
	public function should_nullify_parent_on_removeChild():Void
	{
		instance = new MockView();
		childInstance = new MockView();
		instance.addChild(childInstance);
		instance.removeChild(childInstance);

		Assert.areEqual(null, childInstance.parent);
		Assert.areEqual(-1, childInstance.index);
	}

	@AsyncTest
	public function should_dispatch_removed_on_removeChild(factory:AsyncFactory):Void
	{
		var handler:Dynamic = factory.createHandler(this, removedHandler, 300);
		
		instance = new MockView();

		instance.on("removed", handler);

		childInstance = new MockView();
		instance.addChild(childInstance);
		instance.removeChild(childInstance);
	}

	@AsyncTest
	public function should_dispatch_removed_for_all_descendants(factory:AsyncFactory):Void
	{
		var handler:Dynamic = factory.createHandler(this, assertRemovedCount, 300);
		
		instance = new MockView();

		instance.on("removed", removedViewHandler);

		childInstance = new MockView();
		var grandChildInstance = new MockView();

		childInstance.addChild(grandChildInstance);
		instance.addChild(childInstance);

		instance.removeChild(childInstance);

		Timer.delay(handler, 200);
	}

	function removedViewHandler(event)
	{
		removedCount ++;
	}

	@Test
	public function should_ignore_removeChild_on_non_child():Void
	{
		instance = new MockView();
		childInstance = new MockView();
		instance.removeChild(childInstance);

		Assert.areEqual(null, childInstance.parent);
		Assert.areEqual(-1, childInstance.index);
	}

	@Test
	public function should_update_sibling_indexes_on_removeChild():Void
	{
		instance = new MockView();
		childInstance = new MockView();

		instance.addChild(childInstance);

		var childInstance2 = new MockView();
		instance.addChild(childInstance2);

		Assert.areEqual(1, childInstance2.index);

		instance.removeChild(childInstance);

		Assert.areEqual(0, childInstance2.index);
	}


	// //-------------------------------------------------------------------------- removeAllChildren

	@Test
	public function should_removeAllChildren():Void
	{
		instance = new MockView();
		childInstance = new MockView();

		instance.addChild(childInstance);
		instance.removeAllChildren();

		Assert.areEqual(null, childInstance.parent);
		Assert.areEqual(-1, childInstance.index);
	}


	// //-------------------------------------------------------------------------- destroy
	
	@Test
	public function should_remove_all_descendants_on_destroy():Void
	{
		instance = new MockView();
		childInstance = new MockView();

		instance.addChild(childInstance);

		instance.destroy();

		Assert.isTrue(childInstance.destroyed);

		Assert.areEqual(null, childInstance.parent);
		Assert.areEqual(-1, childInstance.index);
	}


	// //-------------------------------------------------------------------------- template

	@Test
	public function should_have_empty_innerHTML():Void
	{
		instance = new MockView();
		Assert.areEqual("", instance.element.html());
	}


	@Test
	public function should_have_template_from_metadata_in_innerHTML():Void
	{
		var instance = new MockViewWithTemplate();
		Assert.areEqual("This is some text", instance.element.html());
	}

	// //-------------------------------------------------------------------------- 
	
	@Test
	public function should_return_className_and_id_in_toString():Void
	{
		instance = new MockView();

		var id = instance.id;

		Assert.isTrue(StringTools.startsWith(id, "MockView"));
		Assert.areEqual("MockView(" + id + ")", instance.toString());
	}


	@Test
	public function should_use_existing_element():Void
	{
		var node = Lib.document.createElement("div");
		node.innerHTML = "value";
		node.setAttribute("id", "tempNode");
		temp.appendChild(node);

		var view = View.fromId(data, "tempNode");
		Assert.areEqual("value", view.element.html());

	}

	@Test
	public function should_use_element_type():Void
	{
		var view = View.fromType(data, "ul");
		Assert.isTrue(view.element.is("ul"));

	}

	 //-------------------------------------------------------------------------- asserts
	

	function assertDataNotChanged()
	{
		Assert.isTrue(changedValues.join(",").indexOf("data") == -1);
	}


	function assertAddedCount()
	{
		Assert.areEqual(2, addedCount);
	}

	function assertRemovedCount()
	{
		Assert.areEqual(2, removedCount);
	}


}

private class MockView extends View<MockData>
{
	public var destroyed:Bool;

	public function new(?data:MockData=null, ?element:JQuery=null)
	{
		super(data, element);
		destroyed = false;
	}

	public function getContainer():JQuery
	{
		return container;
	}

	override function destroy()
	{
		super.destroy();
		destroyed = true;
	}
}

@template("jhx/mock.html")
private class MockViewWithTemplate extends MockView
{
	public function new(?data:MockData=null, ?element:JQuery=null)
	{
		super(data, element);
	}
}

private class MockData
{
	public function new()
	{

	}
}