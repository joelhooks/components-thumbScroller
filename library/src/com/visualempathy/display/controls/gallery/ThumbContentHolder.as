package com.visualempathy.display.controls.gallery
{
	import flash.display.Graphics;
	import flash.display.Shape;
	
	import mx.core.FlexSprite;
	import mx.core.UIComponent;
	
	public class ThumbContentHolder extends UIComponent
	{
		private var _selectionLayer:FlexSprite;

		public function get selectionLayer():FlexSprite
		{
			return _selectionLayer;
		}


		public function set selectionLayer(value:FlexSprite):void
		{
			_selectionLayer = value;
		}

		private var maskShape:Shape;
		private var thumbScroller:ThumbScroller;
		
		public function ThumbContentHolder(thumbScroller:ThumbScroller)
		{
			this.thumbScroller = thumbScroller;
			// This invisible layer, which is a child of listContent
			// catches mouse events for all items
			// and is where we put selection highlighting by default.
			if (!selectionLayer)
			{
				selectionLayer = new FlexSprite();
				selectionLayer.name = "selectionLayer";
				selectionLayer.mouseEnabled = false;
				addChild(selectionLayer);
				
				// trace("selectionLayer parent set to " + selectionLayer.parent);
				
				var g:Graphics = selectionLayer.graphics;
				g.beginFill(0, 1); // 0 alpha means transparent
				g.drawRect(0, 0, 10, 10);
				g.endFill();
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number,
													  unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			// have to resize selection layer without scaling so refill it
			var g:Graphics = selectionLayer.graphics;
			g.clear();
			if (unscaledWidth > 0 && unscaledHeight > 0)
			{
				g.beginFill(0x808080, 0);
				g.drawRect(0, 0, unscaledWidth, unscaledHeight);
				g.endFill();
			}
			
			if (maskShape)
			{
				maskShape.width = unscaledWidth;
				maskShape.height = unscaledHeight;
			}
		}
	}
}