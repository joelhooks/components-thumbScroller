/**
 * Created by Joel Hooks | joelhooks@gmail.com
 * Feel free to use this however you like, but leave this comment intact.
 * http://creativecommons.org/licenses/by/3.0/
 */
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
			_selectionLayer=value;
		}

		private var maskShape:Shape;
		private var thumbScroller:ThumbScroller;

		public function ThumbContentHolder(thumbScroller:ThumbScroller)
		{
			this.thumbScroller=thumbScroller;
			if (!selectionLayer)
			{
				selectionLayer=new FlexSprite();
				selectionLayer.name="selectionLayer";
				selectionLayer.mouseEnabled=false;
				addChild(selectionLayer);

				var g:Graphics=selectionLayer.graphics;
				g.beginFill(0, 0);
				g.drawRect(0, 0, 10, 10);
				g.endFill();
			}
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			var g:Graphics=selectionLayer.graphics;
			g.clear();
			if (unscaledWidth > 0 && unscaledHeight > 0)
			{
				g.beginFill(0x808080, 0);
				g.drawRect(0, 0, unscaledWidth, unscaledHeight);
				g.endFill();
			}

			if (maskShape)
			{
				maskShape.width=unscaledWidth;
				maskShape.height=unscaledHeight;
			}
		}
	}
}