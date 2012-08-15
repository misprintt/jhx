package jhx.core;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import jhx.core.Changeable;

/**
* Auto generated MassiveUnit Test Class  for jhx.core.Changeable 
*/
class ChangeableTest 
{
	var instance:Mock; 

	var changed:Bool;
	var values:Array<String>;
	
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
		values = [];
		changed = false;
	}
	
	@After
	public function tearDown():Void
	{
	}

	//-------------------------------------------------------------------------- validation
	
	
	@AsyncTest
	public function should_dispatch_change_all(factory:AsyncFactory):Void
	{
		var handler:Dynamic = factory.createHandler(this, changedAllHandler, 300);
		instance = new Mock();
		instance.on("all", handler);
		instance.property = "foo";
	}	

	function changedAllHandler(event)
	{
		changed = true;
		values.push("all");

		Assert.areEqual(Mock, Type.getClass(event.target));
		var type = ChangeableEventType.Changed("all");
		Assert.isTrue(Type.enumEq(type, event.type));
	}

	@AsyncTest
	public function should_dispatch_property_change(factory:AsyncFactory):Void
	{
		var handler:Dynamic = factory.createHandler(this, propertyChangedHandler, 300);
		instance = new Mock();
		instance.on("property", handler);
		instance.property = "foo";
	}	

	function propertyChangedHandler(event)
	{
		changed = true;
		values.push("property");

		Assert.areEqual(Mock, Type.getClass(event.target));
		
		var type = ChangeableEventType.Changed("property");
		Assert.isTrue(Type.enumEq(type, event.type));

	}

	@AsyncTest
	public function should_not_dispatch_if_off(factory:AsyncFactory):Void
	{
		var handler:Dynamic = factory.createHandler(this, assertPropertyNotChanged, 300);

		instance = new Mock();
		changed = false;
		
		instance.on("property", propertyChangedHandler);
		
		Assert.isTrue(instance.off("property", propertyChangedHandler));
		instance.property = "foo";

		Timer.delay(handler, 200);
	}	

	function assertPropertyNotChanged()
	{
		Assert.isTrue(values.join(",").indexOf("property") == -1);
	}

	@AsyncTest
	public function should_dispatch_property_before_all(factory:AsyncFactory):Void
	{
		var handler:Dynamic = factory.createHandler(this, assertPropertyChangedBeforeAll, 300);

		instance = new Mock();
		changed = false;

		instance.on("property", propertyChangedHandler);
		instance.on("all", changedAllHandler);
		
		instance.property = "foo";

		Timer.delay(handler, 200);
	}	

	function assertPropertyChangedBeforeAll()
	{
		Assert.isTrue(changed);

		var values = values.join(",");
		Assert.isTrue(values.indexOf("property") > -1);
		Assert.isTrue(values.indexOf("all") > values.indexOf("property") );
	}

	@Test
	public function should_not_dispatch_changed_if_unchanged():Void
	{
		instance = new Mock();

		instance.on("property", propertyChangedHandler);
		instance.on("all", changedAllHandler);
		
		instance.validate();

		Assert.isFalse(changed);
	}

	@AsyncTest
	public function should_not_dispatch_property_changed_if_reverted_to_original_value(factory:AsyncFactory):Void
	{
		var handler:Dynamic = factory.createHandler(this, assertPropertyNotChanged, 300);

		instance = new Mock();
		changed = false;

		instance.on("property", propertyChangedHandler);
		instance.on("all", changedAllHandler);
		
		instance.property = "foo";
		instance.property = null;

		Timer.delay(handler, 200);
	}	


	@AsyncTest
	public function should_remove_duplicate_handler_references_from_on(factory:AsyncFactory):Void
	{
		var handler:Dynamic = factory.createHandler(this, assertPropertyChangedOnce, 300);

		instance = new Mock();
		changed = false;

		instance.on("property", propertyChangedHandler);
		instance.on("property", propertyChangedHandler);
		
		instance.property = "foo";

		Timer.delay(handler, 200);
	}	


	function assertPropertyChangedOnce()
	{
		Assert.isTrue(changed);
		Assert.isTrue(values.join(",").lastIndexOf("property") == 0);
	}

}

private class Mock extends Changeable<Mock>
{
	public var property(default, set_property):String;

	function set_property(value:String):String
	{
		return set("property", value);
	}

	public function new()
	{
		super();
	}
}