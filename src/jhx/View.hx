package jhx;

import msignal.EventSignal;

import js.Lib;
import js.Dom;
import js.JQuery;

import jhx.core.Validator;
import jhx.core.Changeable;

typedef AnyView = View<Dynamic>;

@:autoBuild(jhx.ViewMacro.build())
class View<TData> extends Changeable<View<TData>>
{
	static public inline var ADDED:String = "added";
	static public inline var REMOVED:String = "removed";
	
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

	
	/**
	 * Unique identifier (viewXXX);
	 */
	public var id(default, null):String;

	/**
	 * Current data value
	 * @see setData()
	 */
	@set @get var data:TData;

	/**
	 * reference to the index relative to siblings
	 * defaults to -1 when view has no parent 
	 * @see View.addChild()
	 */
	@set var index:Int;


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
	
	/**
	 * Reference to previous data object
	 */
	var previousData:TData;

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

	
	var template:haxe.Template;

	var containerSelector:String;
	
	public var html(default, null):String;

	
	public function new(?data:TData=null, ?element:JQuery=null)
	{
		super();

		if(element != null)
			this.element = element;

		className = Type.getClassName(Type.getClass(this)).split(".").pop();

		
		children = [];

		//set default index without triggering setter
		Reflect.setField(this, "index", -1);

		initialize();

		if(data != null)
			setData(data);
	}

	//-------------------------------------------------------------------------- core

	

	/**
	 * Sets the data property and triggers a DATA_CHANGED event
	 * @param data 	data to set
	 * @param forced 	forces change even if data object is identical
	 */
	public function setData(data:TData, ?forced:Bool=false)
	{
		if(this.data != data || forced == true)
		{
			previousData = this.data;
			
			data = set("data", data);

			if(forced)
			{
				this.data = data;
				trigger("data");
			}
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

	override function validated(flag:Dynamic)
	{
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

		trigger(View.ADDED);
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

		trigger(View.REMOVED);
	}

}


