package jhx.core;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import jhx.core.Validator;

/**
* Auto generated MassiveUnit Test Class  for jhx.Validator 
*/
class ValidatorTest 
{
	var instance:Validator; 
	var item1:ValidatableItem;
	var item2:ValidatableItem;
	
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
		instance = new Validator();
		item1 = new ValidatableItem();
		item2 = new ValidatableItem();
	}
	
	@After
	public function tearDown():Void
	{
	}

	@AsyncTest
	public function should_validate_item(factory:AsyncFactory):Void
	{
		instance.invalidate(item1);

		var handler:Dynamic = factory.createHandler(this, assertItemIsValidated, 300);
		Timer.delay(handler, 200);
	}
	
	private function assertItemIsValidated():Void
	{
		Assert.isTrue(item1.valid);
	}

}


private class ValidatableItem implements Validatable
{
	public var valid:Bool;

	public function new()
	{
		valid = false;
	}
	
	public function validate():Void
	{
		valid = true;
	}
}