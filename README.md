jhx
===

A Haxe JavaScript View Framework

View component that composes a JQuery element and a typed data property.


Features:

* html layout templates (via metadata)
* property validation and template binding
* event signals for added/removed/property changes (on, off, trigger)
* display API (addChild, removeChild, removeAllChildren)
* lifecycle (initialize, added, render, removed, destroy )


> **Please Note:"** This is a work in progress and is subject to change :)

### View

A View is a typed data component

	var view = new View<String>();
	view.setData("foo");

or
	var view = new View<String>("foo");

It wraps a JQuery html element via the `element` property

	view.element.find("...");

By default this is an empty div, but you can specify an existing element

	var view = new View<String>("foo", existingJQueryElement);

You can also use a couple of shortcutgs

	View.fromId("foo", elementId);
	View.fromType("foo", "li");


### View Templates

A core feature of JHX is the binding of html layout template files to a View class


Html templates are specified via metadata

	@template("path/to/template.html")


This uses the haxe.Template to set values

	<h1>::title::</h1>
	<h2>::description::</h2>
	<ul></ul>


By default children are added as direct children of the element.

To customise, set a jquery selector in the template metadata

	@template("path/to/template.html", "ul")

This instructs the view to attach children elements using the template's selector (equivalant of `element.find("ul")`)


### Property/Template binding

By default a view is invalidated when the data property is changed.

It can be applied to other properties via the set method

	set("propertyName", value);

This can be easily be wrapped in getter/setters

	public var property(default, set_property):String;

	function set_property(value:String):String
	{
		return set("property", value);
	}

Calling set causes a delayed (one milisecond) invalidation cycle.

During validation the following occurs:

- dispatches an Changed(propertyName) event for each modified property
- dispatches a Changed("all")
- calls view.render() to reapply template if properties have changed

You can overwrite the render function to customise accordingly.


### Events

Views bubble EventSignals to parent views via an event property.

JHX provides some shortcut methods for adding/removing listeners:

To add a listener to a an event

	view.on(Added, addedHandler);

To remove a listener

	view.off(Added, addedHandler);

To trigger an event manually

	view.trigger(Added);

To add a listener to a single property change

	view.on("propertyName", propertyNameChangedHander);
	view.trigger("propertyName");

To listen to all property changes

	view.on("all", changeHandler);

This is the equivalent of

	view.on(Changed(null), changeHandler)

The `event` property is an EventSignal, so it can be used directly

To listen to all events

	view.event.add(eventHandler);
	view.event.add(eventHandler).forType(Added);
	view.event.remove(eventHandler);


An actual listener follows the following format:

	function eventHandler(event<View<Dynamic>, ViewEventType>)
	{
		trace(event.target == childView);
		trace(event.type == Added)
	}


### View hierachy

You can add and remove child views

	root = new View<Dynamic>();
	child = new View<Dynamic>();

	root.addChild(child);
	root.removeChild(child);


Views dispatch EventSignals when added/removed

	root.on(Added, addedHandler);
	root.off(Added, addedHandler);

By default a child's element is appended to the parent's element. This can be customised by using template metadata:

		@template("path/to/template.html", "ul")

Or by setting the'containerSelector' property on a view:

	class CustomView extends View<CustomData>
	{
		public function new(?data:CustomData, ?element:JQuery=null)
		{
			super(data, element);
			containerSelector = "ul";
		}
	}

