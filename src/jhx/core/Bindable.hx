package jhx.core;
import jhx.core.Validator;
import msignal.EventSignal;

enum BindableEventType
{
	Changed(name:String);
}

typedef AnyBindable = Bindable<Dynamic>;

class Bindable<TBindable> implements Validatable, implements EventDispatcher<Event<TBindable, BindableEventType>>
{
	static var validator:Validator = new Validator();

	public var event(default, null):EventSignal<TBindable, BindableEventType>;

	/**
	 * Reference to inChanged property values
	 */
	var previousValues:Dynamic;


	var changeHandlers:Hash<Array<Event<TBindable, BindableEventType> -> Void>>;


	public function new()
	{
		var target:TBindable = cast this;
		event = new EventSignal<TBindable, BindableEventType>(target);

		previousValues = {};
		changeHandlers = new Hash();
		event.add(changed).forType(BindableEventType.Changed(null));

	}

	/**
	 * Dispatch an event, returning `true` if the event should continue to bubble, 
	 * and `false` if not.
	 */
	public function dispatchEvent(event:Event<TBindable, BindableEventType>):Bool
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

	public function on(type:Dynamic, handler:Event<TBindable, BindableEventType> -> Void)
	{	
		Console.assert(type != null, "type cannot be null : " + Std.string(type));
		
		if(Std.is(type, String))
		{
			if(!changeHandlers.exists(type))
			{
				changeHandlers.set(type, [handler]);
			}
			else
			{
				off(type, handler);
				changeHandlers.get(type).push(handler);
			}
		}
		else
		{
			event.add(handler).forType(type);
		}
	}

	public function off(type:Dynamic, handler:Event<TBindable, BindableEventType> -> Void):Bool
	{
		Console.assert(type != null, "type cannot be null : " + Std.string(type));
		
	
		if(Std.is(type, String))
		{
			if(changeHandlers.exists(type))
			{
				var handlers = changeHandlers.get(type);

				for(i in 0...handlers.length)
				{
					var h = handlers[i];

					if(Reflect.compareMethods(h, handler))
					{
						handlers.splice(i, 1);
						return true;
					}
				}
			}
			return false;
		}
		else
		{
			event.remove(handler).forType(type);
			return true;
		}
	}


	public function trigger(type:Dynamic)
	{
		Console.assert(type != null, "type cannot be null : " + Std.string(type));
		
		if(Std.is(type, String))
		{
			if(Reflect.hasField(previousValues, type))
			{
				Reflect.deleteField(previousValues, type);
			}
			event.bubbleType(Changed(type));
		}
		else if(Std.is(type, BindableEventType))
		{
			event.bubbleType(type);
		}
	}


	function changed(event:Event<TBindable, BindableEventType>)
	{
		switch(event.type)
		{
			case Changed(type):
			{
				if(changeHandlers.exists(type))
				{
					var handlers = changeHandlers.get(type).concat([]);
					for(handler in handlers)
					{
						handler(event);
					}
				}
			}
			default:
		}
	}

	function validated(flag:Dynamic)
	{

	}

}