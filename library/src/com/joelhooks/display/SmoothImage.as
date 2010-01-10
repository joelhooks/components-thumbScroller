
package com.joelhooks.display
{
	import flash.display.Bitmap;
	
	import mx.controls.Image;

	public class SmoothImage extends Image
	{
        override protected function updateDisplayList (unscaledWidth : Number, unscaledHeight : Number) : void
        {
            super.updateDisplayList (unscaledWidth, unscaledHeight);
            // checks if the image is a bitmap
            if (content is Bitmap)
            {
                var bitmap : Bitmap = content as Bitmap;

                if (bitmap != null && bitmap.smoothing == false)
                {
                    bitmap.smoothing = true;
                }
            }
        }
	}
}