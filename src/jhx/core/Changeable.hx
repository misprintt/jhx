package jhx.core;
import jhx.core.Validator;
import msignal.EventSignal;


typedef ChangeableEventType = String;

typedef AnyChangeable = Changeable<Dynamic>;

class Changeable<TChangeable> implements Validatable, implements EventDispatcher<Event<TChangeable, ChangeableEventType>>
{
	static var validator:Validator = new Validator();

	public var event(default, null):EventSignal<TChangeable, ChangeableEventType>;

	/**
	 * Reference to inChanged property values
	 */
	var previousValues:Dynamic;

	var changeHandlers:Hash<Array<Event<TChangeable, ChangeableEventType> -> Void>>;

	public function new()
	{
		var target:TChangeable = cast this;

		previousValues = {};

		event = new EventSignal<TChangeable, ChangeableEventType>(target);
		event.addWithPriority(changed, 1);

	}

	/**
	 * Dispatch an event, returning `true` if the event should continue to bubble, 
	 * and `false` if not.
	 */
	public function dispatchEvent(event:Event<TChangeable, ChangeableEventType>):Bool
	{
		this.event.dispatch(event);
		return true;
	}


	//-------------------------------------------------------------------------- validation

	public function set<TValue>(name:String, value:TValue):TValue
	{
		//Console.assert(Reflect.hasField(this, name), className + "." + name + " does not exist.");
		// Console.assert(Type.typeof(Reflect.field(this, name)) == Type.typeof(value), className + "." + name + " is not of type " + Std.string(Type.typeof(value)));
		
		var current:TValue = Reflect.field(this, name);
		var previous:TValue = Reflect.hasField(previousValues, name) ? Reflect.field(previousValues, name) : null;

		if(current == value)
		{
			//do nothing
		}
		else if(previous == value)
		{
			//restore original value;
			Reflect.setField(this, name, value);
			Reflect.deleteField(previousValues, name);
			
		}
		else
		{
			//value has changed
			Reflect.setField(previousValues, name, current);
			Reflect.setField(this, name, value);

			validator.invalidate(this);
		}

		return value;
	}

	public function validate()
	{
		var changed:Bool = false;

		var flag = previousValues;

		for(field in Reflect.fields(previousValues))
		{
			var previous = Reflect.field(previousValues, field);
			var current = Reflect.field(this, field);

			if(previous != current)
			{
				changed = true;
				trigger(field);
			}
		}

		if(changed)
		{
			previousValues = {};
			validated(flag);
			trigger("all");
		}
	}

	public function on(type:String, handler:Event<TChangeable, ChangeableEventType> -> Void)
	{	
		Console.assert(type != null, "type cannot be null : " + Std.string(type));

		if(type == "all")
			event.add(handler);
		else
			event.add(handler).forType(type);
	}

	public function off(type:String, handler:Event<TChangeable, ChangeableEventType> -> Void)
	{
		Console.assert(type != null, "type cannot be null : " + Std.string(type));
		event.remove(handler);
	}

	public function trigger(type:String)
	{
		Console.assert(type != null, "type cannot be null : " + Std.string(type));
		
		if(Reflect.hasField(previousValues, type))
		{
			Reflect.deleteField(previousValues, type);
		}
		event.bubbleType(type);
	}


	function changed(event:Event<TChangeable, ChangeableEventType>)
	{
		
	}

	function validated(flag:Dynamic)
	{

	}

}