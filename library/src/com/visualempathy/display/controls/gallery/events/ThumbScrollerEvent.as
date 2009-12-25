package com.visualempathy.display.controls.gallery.events
{
	import flash.events.Event;
	
	public class ThumbScrollerEvent extends Event
	{
		public static const THUMB_SELECTED:String = "thumbSelected";
		
		private var _data:Object;

		public function get data():Object
		{
			return _data;
		}

		public function ThumbScrollerEvent(type:String, data:Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			_data = data;
			super(type, bubbles, cancelable);
		}
		
		override public function clone() : Event
		{
			return new ThumbScrollerEvent(type,data,bubbles,cancelable);
		}
	}
}