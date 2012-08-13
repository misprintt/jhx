package jhx;

import msignal.EventSignal;

import js.Lib;
import js.Dom;
import js.JQuery;

import jhx.Validator;

typedef View = DataView<Dynamic>;

enum ViewEventType
{
	Added;
	Removed;
	Actioned;
	Changed(name:String);
}


@:autoBuild(jhx.ViewMacro.build())
class DataView<TData> implements Validatable, implements EventDispatcher<Event<DataView<TData>, ViewEventType>>
{

	public static function fromId<T>(data:T, elementId:String):DataView<T>
	{
		var element = Lib.document.getElementById(elementId);
		return new DataView<T>(data, new JQuery(element));
	}

	public static function fromType<T>(data:T, elementType:String):DataView<T>
	{
		var element = Lib.document.createElement(elementType);
		return new DataView<T>(data, new JQuery(element));
	}



	//-------------------------------------------------------------------------- public previousValues

	public var event(default, null):EventSignal<DataView<TData>, ViewEventType>;
	
	/**
	 * Unique identifier (viewXXX);
	 */
	public var id(default, null):String;

	/**
	 * Current data value
	 * @see setData()
	 */
	public var data(default, null):TData;

	/**
	 * reference to the index relative to siblings
	 * defaults to -1 when view has no parent 
	 * @see View.addChild()
	 */
	public var index(default, set_index):Int;
	function set_index(value:Int):Int {return set("index", value);}


	/**
	 * reference to parent view (if available)
	 * @see View.addChild()
	 * @see View.removeChild()
	 */
	public var parent(default, null):View;

	/**
	 * native html element representing this view in the DOM
	 */
	public var element(default, null):JQuery;


	//-------------------------------------------------------------------------- internal previousValues
	

	static var idCounter:Hash<Int> = new Hash();
	static var validator:Validator = new Validator();

	/**
	 * Reference to previous data object
	 */
	var previousData:TData;


	/**
	 * Reference to inChanged property values
	 */
	var previousValues:Dynamic;

	/**
	 * Optional tag name to use when creating element via Lib.document.createElement
	 * defaults to 'div'
	 */
	var tagName:String;

	
	/**
	 * Contains all children currently added to view
	 */
	var children:Array<View>;

	/**
	 * Container element for children (defaults to same as view.element)
	 */
	public var container(get_container, null):JQuery;
	function get_container():JQuery {return getChildContainer();}

	var className(default, null):String;

	var changeHandlers:Hash<Array<Event<DataView<TData>, ViewEventType> -> Void>>;

	var template:haxe.Template;
	
	public var html(default, null):String;

	
	public function new(?data:TData=null, ?element:JQuery=null)
	{
		if(element != null)
			this.element = element;

		className = Type.getClassName(Type.getClass(this)).split(".").pop();

		previousValues = {};
		children = [];

		event = new EventSignal<DataView<TData>, ViewEventType>(this);

		changeHandlers = new Hash();
		event.add(changed).forType(ViewEventType.Changed("all"));

		//set default index without triggering setter
		Reflect.setField(this, "index", -1);

		initialize();

		if(data != null)
			setData(data);
	}


	//-------------------------------------------------------------------------- core
	/**
	 * Dispatch an event, returning `true` if the event should continue to bubble, 
	 * and `false` if not.
	 */
	public function dispatchEvent(event:Event<DataView<TData>, ViewEventType>):Bool
	{
		this.event.dispatch(event);
		return true;
	}



	
	/**
	 * Sets the data property and triggers a DATA_CHANGED event
	 * @param data 	data to set
	 * @param force 	forces change even if data object is identical
	 */
	public function setData(data:TData, ?force:Bool=false)
	{
		if(this.data != data || force == true)
		{
			previousData = this.data;
			data = set("data", data, force);
			validate();
		}
	}

	//-------------------------------------------------------------------------- display


	/**
	 * Adds a child view to the display heirachy.
	 * @param view 	child to add
	 */
	public function addChild(view:View)
	{
		Console.assert(view != this, "Cannot add self as child");
		Console.assert(view.parent != this, "View already child of this");

		if(view.parent != null)
		{
			view.parent.removeChild(view);
		}

		view.parent = this;
		view.index = children.length;
		container.append(view.element);

		children.push(view);

		view.added();

	}

	/**
	 * Removes an existing child view from the display heirachy.
	 * @param view 	child to remove
	 */
	public function removeChild(view:View)
	{
		var removed = children.remove(view);

		if(removed)
		{
			var oldIndex = view.index;

			view.removed();

			view.parent = null;
			view.index = -1;

			view.element.remove();

			for(i in oldIndex...children.length)
			{
				var view = children[i];
				view.index = i;
			}
		}
	}

	public function removeAllChildren()
	{
		for(child in children.concat([]))
		{
			removeChild(child);
		}
	}

	public function destroy()
	{
		for(child in children.concat([]))
		{
			removeChild(child);
			child.destroy();
		}
	}

	//-------------------------------------------------------------------------- validation

	public function validate()
	{
		var changed:Bool = false;

		for(field in Reflect.fields(previousValues))
		{
			var previous = Reflect.field(previousValues, field);
			var current = Reflect.field(this, field);

			changed = true;
			trigger(field);
		}

		if(changed)
		{
			previousValues = {};
			render();
			trigger("all");
		}
	}

	public function on(name:String, handler:Event<DataView<TData>, ViewEventType> -> Void)
	{
		if(!changeHandlers.exists(name))
		{
			changeHandlers.set(name, []);
		}
		else
		{
			off(name, handler);
		}
		
		changeHandlers.get(name).push(handler);
	}

	public function off(name:String, handler:Event<DataView<TData>, ViewEventType> -> Void):Bool
	{
		if(changeHandlers.exists(name))
		{
			var handlers = changeHandlers.get(name);

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

	public function trigger(?name:String="all")
	{
		event.bubbleType(Changed(name));
	}

	function changed(event:Event<DataView<TData>, ViewEventType>)
	{
		switch(event.type)
		{
			case Changed(field):
			{
				if(changeHandlers.exists(field))
				{
					var handlers = changeHandlers.get(field).concat([]);
					for(handler in handlers)
					{
						handler(event);
					}
				}
			}
			default:
		}
	}

	

	public function set<TValue>(name:String, value:TValue, ?force:Bool=false):TValue
	{
		//Console.assert(Reflect.hasField(this, name), className + "." + name + " does not exist.");
		// Console.assert(Type.typeof(Reflect.field(this, name)) == Type.typeof(value), className + "." + name + " is not of type " + Std.string(Type.typeof(value)));
		
		var current:TValue = Reflect.field(this, name);
		var previous:TValue = Reflect.hasField(previousValues, name) ? Reflect.field(previousValues, name) : null;

		if(current == value  && !force)
		{
			//do nothing
		}
		else if(previous == value && !force)
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


	//-------------------------------------------------------------------------- other

	public function toString():String
	{
		return className + "(" + id + ")";
	}

	//-------------------------------------------------------------------------- lifecycle


	function initialize()
	{
		if(element == null)
		{
			if(tagName == null) tagName = "div";
			var el = Lib.document.createElement(tagName);
			element = new JQuery(el);
		}

		id = element.attr("id");

		if(id == null)
		{
			//create unique identifier for this view

			if(!idCounter.exists(className))
			{
				idCounter.set(className, 0);
			}

			var count = idCounter.get(className);

			id = className + count++;

			idCounter.set(className, count);

			element.attr("id", id);
		}

		element.addClass(className);

		if(Reflect.hasField(this, "templateId"))
		{
			var templateContent = haxe.Resource.getString(Reflect.field(this, "templateId"));
			template = new haxe.Template(templateContent);
		}
		else
		{
			template = new haxe.Template("");
		}

		render();
	}

	function getChildContainer():JQuery
	{
		return element;
	}

	function render()
	{
		var temp = template.execute(this);

		if(temp != html && temp != "")
		{
			html = temp;
			element.html(html);

			for(child in children)
			{
				container.append(child.element);
			}
		}
	}

	function added()
	{
		for(child in children)
		{
			child.added();
		}

		event.bubbleType(Added);
	}

	function removed()
	{
		for(child in children)
		{
			child.removed();
		}

		event.bubbleType(Removed);
	}

}


