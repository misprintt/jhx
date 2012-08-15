import massive.munit.TestSuite;

import jhx.core.BindableTest;
import jhx.core.ValidatorTest;
import jhx.ViewTest;

/**
 * Auto generated Test Suite for MassiveUnit.
 * Refer to munit command line tool for more information (haxelib run munit)
 */

class TestSuite extends massive.munit.TestSuite
{		

	public function new()
	{
		super();

		add(jhx.core.BindableTest);
		add(jhx.core.ValidatorTest);
		add(jhx.ViewTest);
	}
}
