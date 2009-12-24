package com.visualempathy.display.controls.gallery
{
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	import mx.collections.CursorBookmark;
	import mx.collections.ICollectionView;
	import mx.collections.IList;
	import mx.collections.IViewCursor;
	import mx.collections.ItemWrapper;
	import mx.collections.ListCollectionView;
	import mx.collections.XMLListCollection;
	import mx.collections.errors.ItemPendingError;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.controls.listClasses.ListBaseSelectionData;
	import mx.controls.listClasses.ListItemRenderer;
	import mx.core.ClassFactory;
	import mx.core.FlexShape;
	import mx.core.FlexSprite;
	import mx.core.IFactory;
	import mx.core.IInvalidating;
	import mx.core.IUIComponent;
	import mx.core.UIComponent;
	import mx.core.UIComponentGlobals;
	import mx.core.mx_internal;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.FlexEvent;

	use namespace mx_internal;
	
	/**
	 * This is a continuous (infinite) thumbnail scroller.
	 * Borrowing heavily from the standard Flex 3 List, it performs
	 * in a similar manner. An item renderer should be provided
	 * to display your content appropriatly.
	 * 
	 * <p>The dataProvider is set once, the component does not detect changes
	 * to the dataProvider after it is initially set. This is a product of how the 
	 * component functions in rendering with the reordering of the actual display
	 * to achieve the "infinite" effect.</p>
	 *  
	 * Based on the work of Peter Wright:
	 * http://www.f-90.co.uk/blog/
	 * 
	 * @author Joel Hooks joelhooks[at]gmail[dot]com
	 * 
	 */	
	public class ThumbScroller extends UIComponent
	{
		protected var centerX:Number
		protected var selectedThumb:Object;
		protected var thumbRenderers:Array;
		protected var thumbContent:ThumbContentHolder;
		protected var maskShape:Shape;
		protected var measuringObjects:Dictionary;
		protected var itemsNeedMeasurement:Boolean=true;
		protected var explicitThumbHeight:Number;
		protected var explicitThumbWidth:Number;

		//----------------------------------
		//  thumbHeight
		//----------------------------------
		
		private var _thumbHeight:Number;

		[Inspectable(category="Data")]
		public function get thumbHeight():Number
		{
			return _thumbHeight;
		}

		public function set thumbHeight(value:Number):void
		{
			explicitThumbHeight=value;

			if (_thumbHeight != value)
			{
				setThumbHeight(value);

				invalidateSize();
				itemsSizeChanged=true;
				invalidateDisplayList();

				dispatchEvent(new Event("thumbHeightChanged"));
			}
		}

		protected function setThumbHeight(v:Number):void
		{
			_thumbHeight=v;
		}

		//----------------------------------
		//  thumbWidth
		//----------------------------------
		
		private var _thumbWidth:Number;

		private var thumbWidthChanged:Boolean=false;

		[Inspectable(category="Data")]
		public function get thumbWidth():Number
		{
			return _thumbWidth;
		}

		public function set thumbWidth(value:Number):void
		{
			explicitThumbWidth=value;

			if (_thumbWidth != value)
			{
				setThumbWidth(value);

				invalidateSize();
				itemsSizeChanged=true;
				invalidateDisplayList();

				dispatchEvent(new Event("thumbWidthChanged"));
			}
		}
		
		protected function setThumbWidth(value:Number):void
		{
			_thumbWidth=value;
		}

		//----------------------------------
		//  selectionLayer
		//----------------------------------
		
		private var _selectionLayer:FlexSprite;

		public function get selectionLayer():FlexSprite
		{
			return _selectionLayer;
		}

		public function set selectionLayer(value:FlexSprite):void
		{
			_selectionLayer=value;
		}

		//----------------------------------
		//  selectedItem
		//----------------------------------
		
		private var _selectedItem:Object
		private var selectedItemChanged:Boolean = false;
		
		[Bindable("change")]
		[Bindable("valueCommit")]
		[Inspectable(category="General", defaultValue="null")]
		public function get selectedItem():Object
		{
			return _selectedItem;
		}

		public function set selectedItem(data:Object):void
		{
			if (!collection || collection.length == 0)
			{
				_selectedItem = data;
				selectedItemChanged = true;
				
				invalidateDisplayList();
				return;
			}
			
			commitSelectedItem(data);
		}

		//----------------------------------
		//  damping
		//----------------------------------
		
		private var _damping:Number;
		
		[Inspectable(category="Data")]
		public function get damping():Number
		{
			return _damping;
		}

		public function set damping(value:Number):void
		{
			_damping=value;
		}

		//----------------------------------
		//  itemRenderer
		//----------------------------------

		/**
		 *  @private
		 *  Storage for the itemRenderer property.
		 */
		private var _itemRenderer:IFactory;
		
		protected var itemsSizeChanged:Boolean=false;
		protected var rendererChanged:Boolean=false;

		[Inspectable(category="Data")]
		public function get itemRenderer():IFactory
		{
			return _itemRenderer;
		}

		public function set itemRenderer(value:IFactory):void
		{
			_itemRenderer=value;

			invalidateSize();
			invalidateDisplayList();

			itemsSizeChanged=true;
			rendererChanged=true;
			createItemRenderer({});
			dispatchEvent(new Event("itemRendererChanged"));
		}

		//----------------------------------
		//  nullItemRenderer
		//----------------------------------

		private var _nullItemRenderer:IFactory;

		[Inspectable(category="Data")]
		public function get nullItemRenderer():IFactory
		{
			return _nullItemRenderer;
		}

		public function set nullItemRenderer(value:IFactory):void
		{
			_nullItemRenderer=value;

			invalidateSize();
			invalidateDisplayList();

			itemsSizeChanged=true;
			rendererChanged=true;

			dispatchEvent(new Event("nullItemRendererChanged"));
		}

		//----------------------------------
		//  dataProvider
		//----------------------------------
		
		protected var iterator:IViewCursor
		protected var collectionIterator:IViewCursor;
		
		protected var collection:ICollectionView;

		[Inspectable(category="Data")]
		public function get dataProvider():Object
		{
			return collection;
		}

		public function set dataProvider(value:Object):void
		{
			if (collection)
			{
				collection.removeEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler);
			}
			
			if (value is Array)
			{
				collection=new ArrayCollection(value as Array);
			}
			else if (value is ICollectionView)
			{
				collection=ICollectionView(value);
			}
			else if (value is IList)
			{
				collection=new ListCollectionView(IList(value));
			}
			else if (value is XMLList)
			{
				collection=new XMLListCollection(value as XMLList);
			}
			else if (value is XML)
			{
				var xl:XMLList=new XMLList();
				xl+=value;
				collection=new XMLListCollection(xl);
			}
			else
			{
				var tmp:Array=[];
				if (value != null)
					tmp.push(value);
				collection=new ArrayCollection(tmp);
			}

			iterator=collection.createCursor();
			collectionIterator=collection.createCursor(); //IViewCursor(collection);
			
			collection.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler, false, 0, true);
			
			var event:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
			event.kind = CollectionEventKind.RESET;
			collectionChangeHandler(event);
			dispatchEvent(event);

			itemsNeedMeasurement=true;
			invalidateProperties();
			invalidateSize();
			invalidateDisplayList();
		}
		
		/**
		 * ThumbScroller constructor
		 * 
		 */
		public function ThumbScroller()
		{
			selectedItem = null;
			itemRenderer=new ClassFactory(ListItemRenderer);
			thumbWidth=85;
			centerX=500;
			thumbRenderers=[];
			_damping=10;
			addEventListener(FlexEvent.CREATION_COMPLETE, handleCreationComplete);
			addEventListener(MouseEvent.CLICK, mouseClickHandler);

			invalidateProperties();
		}

		/**
		 * We want to center the navigation once the component has finished 
		 * the creation process. The first item in the dataProvider is moved to
		 * the center position.
		 *  
		 * @param event
		 * 
		 */		
		private function handleCreationComplete(event:Event):void
		{
			centerNav();
		}

		override protected function measure():void
		{
			super.measure();
			measuredHeight=thumbWidth;
			measuredWidth=thumbRenderers.length * thumbWidth;
		}

		override protected function createChildren():void
		{
			super.createChildren();

			if (!thumbContent)
			{
				thumbContent=new ThumbContentHolder(this)
				addChild(thumbContent);
			}

			if (!selectionLayer)
				selectionLayer=thumbContent.selectionLayer;

			if (!maskShape)
			{
				maskShape=new FlexShape();
				maskShape.name="mask";

				var g:Graphics=maskShape.graphics;
				g.beginFill(0xFFFFFF);
				g.drawRect(0, 0, 10, 10);
				g.endFill();

				addChild(maskShape);
				mask=maskShape;
			}

			maskShape.visible=false;

			invalidateSize();
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			var collectionHasItems:Boolean=(collection && collection.length > 0);
			
			if (rendererChanged)
				purgeItemRenderers();
			
			adjustMask(unscaledWidth, unscaledHeight);
			adjustContent(unscaledWidth, unscaledHeight);
			adjustCenterTarget();
			
			if (collectionHasItems && thumbRenderers.length <= 0)
				makeThumbs();
		}
		
		private function adjustCenterTarget():void
		{
			centerX=(collection.length * thumbWidth) / 2;
		}
		
		private function adjustMask(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var mask:DisplayObject=maskShape;
			mask.width=unscaledWidth;
			mask.height=unscaledHeight;
			mask.x=0;
			mask.y=0;		
		}
		
		private function adjustContent(unscaledWidth:Number, unscaledHeight:Number):void
		{
			thumbContent.setActualSize(unscaledWidth, unscaledHeight);
			thumbContent.x=width / 2 - (collection.length * thumbWidth) / 2
		}

		override protected function commitProperties():void
		{
			super.commitProperties();


			if (itemsNeedMeasurement)
			{
				itemsNeedMeasurement=false;
				if (isNaN(explicitThumbHeight))
				{
					if (iterator)
					{
						// trace("calculate height " + index + " " + count);
						var item:IListItemRenderer=getMeasuringRenderer(iterator.current);

						var ww:Number=85;
						if (thumbContent.width)
							ww=thumbContent.width;
						item.explicitWidth=ww;

						setupRendererFromData(item, iterator.current);

						var th:int=item.getExplicitOrMeasuredHeight();

						// unless specified otherwise, thumbheight defaults to 85
						setThumbHeight(Math.max(th, 85));
					}
					else
						setThumbHeight(85);
				}
				if (isNaN(explicitThumbWidth))
					setThumbWidth(measureWidthOfItems(0, collection.length));
			}
		}

		/**
		 *  @private
		 */
		mx_internal function setupRendererFromData(item:IListItemRenderer, wrappedData:Object):void
		{
			var data:Object=(wrappedData is ItemWrapper) ? wrappedData.data : wrappedData;

			item.data=data;

			if (item is IInvalidating)
				IInvalidating(item).invalidateSize();

			UIComponentGlobals.layoutManager.validateClient(item, true);
		}

		/**
		 *  @private
		 */
		public function measureWidthOfItems(index:int=-1, count:int=0):Number
		{
			if (count == 0)
				count=(collection) ? collection.length : 0;

			// if empty collection, don't measure anything
			if (collection && collection.length == 0)
				count=0;

			var item:IListItemRenderer

			var w:Number=0;

			var bookmark:CursorBookmark=(iterator) ? iterator.bookmark : null;
			if (index != -1 && iterator)
			{
				try
				{
					iterator.seek(CursorBookmark.FIRST, index);
				}
				catch (e:ItemPendingError)
				{
					// even the first item isn't paged in
					return 0;
				}

			}
			var rw:Number;
			var more:Boolean=iterator != null;
			for (var i:int=0; i < count; i++)
			{
				var data:Object;
				if (more)
				{
					data=iterator.current;
					var factory:IFactory=getItemRendererFactory(data);
					item=measuringObjects[factory];
					if (!item)
					{
						item=getMeasuringRenderer(data);
					}

					item.explicitWidth=NaN; // gets set in measureHeightOfItems
					setupRendererFromData(item, data);

					rw=item.measuredWidth;
					w=Math.max(w, rw);
				}

				if (more)
				{
					try
					{
						more=iterator.moveNext();
					}
					catch (e:ItemPendingError)
					{
						// if we run out of data, assume all remaining rows are the size of the previous row
						more=false;
					}
				}
			}

			if (iterator)
				iterator.seek(bookmark, 0);

			if (w == 0)
			{
				if (explicitWidth)
					return explicitWidth;
				else
					return DEFAULT_MEASURED_WIDTH;
			}

			return w;
		}

		/**
		 *  @private
		 */
		public function measureHeightOfItems(index:int=-1, count:int=0):Number
		{
			if (count == 0)
				count=(collection) ? collection.length : 0;


			var ww:Number=200;
			if (thumbContent.width)
				ww=thumbContent.width;

			var h:Number=0;

			var bookmark:CursorBookmark=(iterator) ? iterator.bookmark : null;
			if (index != -1 && iterator)
				iterator.seek(CursorBookmark.FIRST, index);

			var th:Number=thumbHeight;
			var more:Boolean=iterator != null;
			for (var i:int=0; i < count; i++)
			{
				var data:Object;
				if (more)
				{
					th=thumbHeight;
					data=iterator.current;

					// trace("calculate height " + index + " " + count);
					var item:IListItemRenderer=getMeasuringRenderer(data);
					item.explicitWidth=ww;

					setupRendererFromData(item, data);
				}
				h+=th;

				if (more)
				{
					try
					{
						more=iterator.moveNext();
					}
					catch (e:ItemPendingError)
					{
						// if we run out of data, assume all remaining rows are the size of the previous row
						more=false;
					}
				}
			}

			if (iterator)
				iterator.seek(bookmark, 0);

			return h;
		}

		[Inspectable(category="Data")]

		/**
		 *  @private
		 */
		protected function getMeasuringRenderer(data:Object):IListItemRenderer
		{
			var item:IListItemRenderer;
			if (!measuringObjects)
				measuringObjects=new Dictionary(true);

			var factory:IFactory=getItemRendererFactory(data);
			item=measuringObjects[factory];

			if (!item)
			{
				item=createItemRenderer(data);
				item.owner=this;
				item.name="hiddenItem";
				item.visible=false;
				thumbContent.addChild(DisplayObject(item));
				measuringObjects[factory]=item;
			}

			return item;
		}

		/**
		 * Shifts the images to keep the continuous scroll continuous
		 * @private
		 */
		private function swap():void
		{
			alignThumbnails();
			var left:DisplayObject=thumbRenderers[0];
			var right:DisplayObject=thumbRenderers[thumbRenderers.length - 1];

			for (var i:int=0; i < thumbRenderers.length; i++)
			{

				if (left.x < 0 - thumbWidth / 2)
				{
					// moves clips from first to last
					thumbRenderers.push(thumbRenderers.shift());
					left.x=right.x + thumbWidth;
				}

				if (right.x > thumbWidth * thumbRenderers.length - thumbWidth / 2)
				{
					// moves clips from last to first
					thumbRenderers.unshift(thumbRenderers.pop());
					right.x=left.x - thumbWidth;
				}
			}

			invalidateSize();
		}

		protected function makeThumbs():void
		{
			var more:Boolean=true;
			var data:Object;
			var item:IListItemRenderer;
			var count:int=0;
			more=(iterator != null && !iterator.afterLast);
			while (more)
			{
				data=more ? iterator.current : null;
				iterator.moveNext();
				more=!iterator.afterLast;
				item=createItemRenderer(data);
				item.owner=this;
				item.x=count * thumbWidth;
				thumbContent.addChild(DisplayObject(item));
				thumbRenderers.push(item);
				count++;
			}
			selectedItem = collection[0];
			selectedThumb=thumbRenderers[0]
		}

		/**
		 * Moves the selected NavItem to the center of the navigation container.
		 * @private
		 */
		private function centerNav():void
		{
			if(!selectedThumb)
				return;
			removeEventListener(Event.ENTER_FRAME, setPositions);
			for (var i:int=0; i < thumbRenderers.length; i++)
			{
				//TODO: ENable and disable selected/unselected nav items
			}
			addEventListener(Event.ENTER_FRAME, setPositions);
		}

		/**
		 * Set the positions of the NavItems
		 * @param e
		 * @private
		 */
		private function setPositions(e:Event=null):void
		{
			var thisX:Number=DisplayObject(selectedThumb).x + thumbWidth;
			var deltaX:Number=thisX - (centerX + thumbWidth / 2);
			DisplayObject(thumbRenderers[0]).x-=deltaX / _damping;
			swap();
			if (Math.abs(deltaX) < 1)
			{
				removeEventListener(Event.ENTER_FRAME, setPositions);
			}
		}

		/**
		 * Make sure all of the NavItems stay aligned while they are swapped
		 * @private
		 */
		private function alignThumbnails():void
		{
			for (var i:int=1; i < thumbRenderers.length; i++)
			{
				thumbRenderers[i].x=thumbRenderers[i - 1].x + thumbWidth;
			}
		}

		protected function purgeItemRenderers():void
		{
			rendererChanged=false;
			while (thumbRenderers.length)
			{
				var item:IListItemRenderer=IListItemRenderer(thumbRenderers.pop());
				if (item)
					thumbContent.removeChild(DisplayObject(item));
			}
		}

		public function createItemRenderer(data:Object):IListItemRenderer
		{
			var factory:IFactory;

			factory=getItemRendererFactory(data);
			if (!factory)
			{
				if (data == null)
					factory=nullItemRenderer;
				if (!factory)
					factory=itemRenderer;
			}

			var renderer:IListItemRenderer;
			renderer=factory.newInstance();
			renderer.data=data;
			renderer.owner=this;
			return renderer;
		}

		public function getItemRendererFactory(data:Object):IFactory
		{
			if (data == null)
				return nullItemRenderer;

			return itemRenderer;
		}

		protected function mouseClickHandler(event:MouseEvent):void
		{
			var item:IListItemRenderer=mouseEventToItemRenderer(event);
			if (!item)
				return;

			selectedItem=item.data;
			centerNav();
		}
		
		private function commitSelectedItem(data:Object):void
		{
			clearSelected();
			if (data == null)
				return;
			
			for each(var thumbRenderer:IListItemRenderer in thumbRenderers)
			{
				if(thumbRenderer.data == data)
				{
					_selectedItem = data;
					selectedThumb = thumbRenderer;
					break;
				}
			}
			
			dispatchEvent(new FlexEvent(FlexEvent.VALUE_COMMIT));
		}

		protected function clearSelected(transition:Boolean = false):void
		{
			_selectedItem = null;
		}
		
		protected function mouseEventToItemRenderer(event:MouseEvent):IListItemRenderer
		{
			var target:DisplayObject=DisplayObject(event.target);

			while (target && target != this)
			{
				if (target is IListItemRenderer && target.parent == thumbContent)
				{
					if (target.visible)
						return IListItemRenderer(target);
					break;
				}

				if (target is IUIComponent)
					target=IUIComponent(target).owner;
				else
					target=target.parent;
			}

			return null;
		}
		
		protected function collectionChangeHandler(event:Event):void
		{
			var len:int;
			var index:int;
			var i:int;
			var data:ListBaseSelectionData;
			var p:String;
			var selectedUID:String;
			
			//TODO: Implement these handlers to update based on changes
			//to the underlying data.
			
			if (event is CollectionEvent)
			{
				var ce:CollectionEvent = CollectionEvent(event);
				
				if (ce.kind == CollectionEventKind.ADD)
				{
				}
					
				else if (ce.kind == CollectionEventKind.REPLACE)
				{
				}
					
				else if (ce.kind == CollectionEventKind.REMOVE)
				{
					
					// trace("ListBase collectionEvent REMOVE", ce.location, verticalScrollPosition);
					// make sure we've generated rows for the actual data
					// at startup time we might just have blank rows
				}
					
				else if (ce.kind == CollectionEventKind.MOVE)
				{
				}
					
				else if (ce.kind == CollectionEventKind.REFRESH)
				{
				}
					
				else if (ce.kind == CollectionEventKind.RESET)
				{
					// RemoveAll() on ArrayCollection currently triggers a reset
					// Special handling for this case.
				}
				else if (ce.kind == CollectionEventKind.UPDATE)
				{
				}
			}
			
			itemsSizeChanged = true;
			
			invalidateDisplayList();
		}
	}
}