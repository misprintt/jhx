import massive.munit.TestSuite;

import jhx.ValidatorTest;
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

		add(jhx.ValidatorTest);
		add(jhx.ViewTest);
	}
}
