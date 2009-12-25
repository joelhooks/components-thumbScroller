package com.visualempathy.display.controls.gallery
{
	import mx.controls.listClasses.IListItemRenderer;
	import mx.core.UIComponent;
	
	public class DefaultThumbRenderer extends UIComponent implements IListItemRenderer
	{
		public function DefaultThumbRenderer()
		{
			super();
		}
		
		public function get data():Object
		{
			return null;
		}
		
		public function set data(value:Object):void
		{
		}
	}
}