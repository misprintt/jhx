package jhx;

import msignal.EventSignal;

import js.Lib;
import js.Dom;
import js.JQuery;

import jhx.Validator;

typedef AnyView = View<Dynamic>;

enum ViewEventType
{
	Added;
	Removed;
	Actioned;
	Changed(name:String);
}


@:autoBuild(jhx.ViewMacro.build())
class View<TData> implements Validatable, implements EventDispatcher<Event<View<TData>, ViewEventType>>
{

	public static function fromId<T>(data:T, elementId:String):View<T>
	{
		var element = Lib.document.getElementById(elementId);
		return new View<T>(data, new JQuery(element));
	}

	public static function fromType<T>(data:T, elementType:String):View<T>
	{
		var element = Lib.document.createElement(elementType);
		return new View<T>(data, new JQuery(element));
	}

	//-------------------------------------------------------------------------- public previousValues

	public var event(default, null):EventSignal<View<TData>, ViewEventType>;
	
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
	public var parent(default, null):AnyView;

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
	var children:Array<AnyView>;

	/**
	 * Container element for children (defaults to same as view.element)
	 */
	public var container(get_container, null):JQuery;
	function get_container():JQuery {
		if(Reflect.hasField(this, "templateContainerSelector"))
		{

			return element.find(Reflect.field(this, "templateContainerSelector"));
		}
		else if(containerSelector != null)
		{
			return element.find(containerSelector);
		}
		return element;
	}

	var className(default, null):String;

	var changeHandlers:Hash<Array<Event<View<TData>, ViewEventType> -> Void>>;

	var template:haxe.Template;

	var containerSelector:String;
	
	public var html(default, null):String;

	
	public function new(?data:TData=null, ?element:JQuery=null)
	{
		if(element != null)
			this.element = element;

		className = Type.getClassName(Type.getClass(this)).split(".").pop();

		previousValues = {};
		children = [];

		event = new EventSignal<View<TData>, ViewEventType>(this);

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
	public function dispatchEvent(event:Event<View<TData>, ViewEventType>):Bool
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

	public function getTemplateData():Dynamic
	{
		var o:Dynamic = data;
		if(o == null) o = this;

		return o;
	}

	//-------------------------------------------------------------------------- display


	/**
	 * Adds a child view to the display heirachy.
	 * @param view 	child to add
	 */
	public function addChild(view:AnyView)
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
	public function removeChild(view:AnyView)
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

	public function on(type:Dynamic, handler:Event<View<TData>, ViewEventType> -> Void)
	{
		if(Std.is(type, String))
		{
			if(!changeHandlers.exists(type))
			{
				changeHandlers.set(type, []);
			}
			else
			{
				off(type, handler);
			}
			
			changeHandlers.get(type).push(handler);
		}
		else
		{
			event.add(handler).forType(type);
		}
	}

	public function off(type:Dynamic, handler:Event<View<TData>, ViewEventType> -> Void):Bool
	{
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
		if(type == null)
		{
			event.bubbleType(Changed("all"));
		}

		else if(Std.is(type, String))
		{
			event.bubbleType(Changed(type));
		}
		else if(Std.is(type, ViewEventType))
		{
			event.bubbleType(type);
		}

		
	}

	function changed(event:Event<View<TData>, ViewEventType>)
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

	/**
	 * Called during validation to regenerate html from template, updating innerHTML if modified.
	 * 
	 * @see validate()
	 */
	function render()
	{
		var templateData = getTemplateData();
		var temp = template.execute(templateData);

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

	/**
	 * Recusively adds all children, dispatching 'Added' events
	 * 
	 * @see addChild()
	 */
	function added()
	{
		for(child in children)
		{
			child.added();
		}

		event.bubbleType(Added);
	}

	/**
	 * recursively removes all children, dispatching 'Removed' events
	 *
	 * @see removeChild();
	 */
	function removed()
	{
		for(child in children)
		{
			child.removed();
		}

		event.bubbleType(Removed);
	}

}


