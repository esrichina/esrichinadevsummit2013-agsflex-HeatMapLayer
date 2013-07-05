/*
Copyright (c) 2010-2012 Esri

All rights reserved under the copyright laws of the United States
and applicable international laws, treaties, and conventions.

You may freely redistribute and use this sample code, with or
without modification, provided you include the original copyright
notice and use restrictions.

See use restrictions in use_restrictions.txt.
*/
package com.esri.MyHeatMapLayer
{
	
	import com.esri.ags.Graphic;
	import com.esri.ags.TimeExtent;
	import com.esri.ags.clusterers.supportClasses.Cluster;
	import com.esri.ags.events.DetailsEvent;
	import com.esri.ags.events.ExtentEvent;
	import com.esri.ags.events.LayerEvent;
	import com.esri.ags.events.QueryEvent;
	import com.esri.ags.events.TimeExtentEvent;
	import com.esri.ags.geometry.Extent;
	import com.esri.ags.geometry.MapPoint;
	import com.esri.ags.layers.Layer;
	import com.esri.ags.layers.supportClasses.LayerDetails;
	import com.esri.ags.tasks.DetailsTask;
	import com.esri.ags.tasks.QueryTask;
	import com.esri.ags.tasks.supportClasses.Query;
	
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayList;
	import mx.collections.IList;
	import mx.events.FlexEvent;
	import mx.rpc.events.FaultEvent;
	
	import com.esri.MyHeatMapLayer.HeatMapEvent;
	import com.esri.MyHeatMapLayer.HeatMapGradientDict;
	import com.esri.MyHeatMapLayer.HeatMapPoint;
	
	//--------------------------------------
	//  Events
	//--------------------------------------
	/**
	 * Dispatched when the ArcGISHeatMapLayer is in scale range.
	 *
	 * @eventType LayerEvent.IS_IN_SCALE_RANGE_CHANGE
	 */
	[Event("isInScaleRangeChange", type="com.esri.ags.events.LayerEvent")]
	/**
	 * Dispatched when the ArcGISHeatMapLayer successfully loads.
	 *
	 * @eventType LayerEvent.LOAD
	 */
	[Event("load", type="com.esri.ags.events.LayerEvent")]
	/**
	 * Dispatched when the ArcGISHeatMapLayer unsuccessfully loads.
	 *
	 * @eventType LayerEvent.LOAD_ERROR
	 */
	[Event("loadError", type="com.esri.ags.events.LayerEvent")]
	/**
	 * Dispatched when the ArcGISHeatMapLayer successfully updates.
	 *
	 * @eventType LayerEvent.UPDATE_END
	 */
	[Event("updateEnd", type="com.esri.ags.events.LayerEvent")]
	/**
	 * Dispatched when the ArcGISHeatMapLayer starts the update process.
	 *
	 * @eventType LayerEvent.UPDATE_START
	 */
	[Event("updateStart", type="com.esri.ags.events.LayerEvent")]
	/**
	 * Dispatched when the ArcGISHeatMapLayer ends the getDetails process.
	 *
	 * @eventType DetailsEvent.GET_DETAILS_COMPLETE
	 */
	[Event("getDetailsComplete", type="com.esri.ags.events.DetailsEvent")]
	/**
	 * Dispatched when the ArcGISHeatMapLayer starts the refresh process.
	 *
	 * @eventType HeatMapEvent.REFRESH_START
	 */
	[Event("refreshStart", type="HeatMapLayer.HeatMapEvent")]
	/**
	 * Dispatched when the ArcGISHeatMapLayer ends the refresh process.
	 *
	 * @eventType HeatMapEvent.REFRESH_END
	 */
	[Event("refreshEnd", type="HeatMapLayer.HeatMapEvent")]
	
	
	public class ArcGISHeatMapLayer extends Layer
	{
		private var _url:String;
		private var _where:String = "1=1";
		private var _useAMF:Boolean = false;
		private var _proxyURL:String;
		private var _token:String;
		private var _outFields:Array;
		private var _timeExtent:TimeExtent;
		private var _urlPartsArray:Array;
		private var _detailsTask:DetailsTask;
		private var _layerDetails:LayerDetails;
		
		private var _heatMapQueryTask:QueryTask;
		private var _heatMapQuery:Query = new Query();
		
		private var _heatMapTheme:String = HeatMapGradientDict.RAINBOW_TYPE;
		private var _dataProvider:IList;
		private var _gradientDict:Array;
		private var _bitmapData:BitmapData;
		
		private static const POINT:Point = new Point();
		private const BLURFILTER:BlurFilter = new BlurFilter(4, 4);
		private var _densityRadius:int = 25;
		
		//--------------------------------------------------------------------------
		//
		//  New Properties at 3.1
		//
		//--------------------------------------------------------------------------
		private var _shape:Shape = new Shape();
		private var _center:MapPoint;
		private var _world:Number;
		private var _wrapAround:Function;
		
		private const _matrix1:Matrix = new Matrix();
		private const _matrix2:Matrix = new Matrix();
		private const COLORS:Array = [ 0, 0 ];
		private const ALPHAS:Array = [ 1, 1 ];
		private const RATIOS:Array = [ 0, 255 ];
		
		private var _clusterCount:int = 0;
		public var _clusterSize:int = 0;
		private var _clusterMaxWeight:Number = 0.0;
		private var _featureRadiusCalculator:Function = internalFeatureRadiusCalculator;
		private var _clusterRadiusCalculator:Function = internalClusterRadiusCalculator;
		private var _featureIndexCalculator:Function = internalFeatureCalculator;
		private var _clusterIndexCalculator:Function = internalClusterCalculator;
		private var _clusterWeightCalculator:Function = internalWeightCalculator;
		
		
		public var  radius1:Number=25;
		public var  isWind:Boolean=true;
		/**
		 * Creates a new ArcGISHeatMapLayer object.
		 *
		 * @param url URL to the ArcGIS Server REST resource that represents a point layer in map service or feature service.
		 * @param proxyURL The URL to proxy the request through.
		 * @param token Token for accessing a secure dynamic ArcGIS service.
		 *
		 */
		public function ArcGISHeatMapLayer(url:String = null, proxyUrl:String = null, token:String = null)
		{
			mouseEnabled = false;
			mouseChildren = false;
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, creationCompleteHandler, false, 0, true);
			addEventListener(LayerEvent.UPDATE_START, updateStartCompleteHandler, false, 0, true);
			addEventListener(Event.REMOVED, removeCompleteHandler, false, 0, true);
			_url = url;
			_proxyURL = proxyURL;
			_token = token;
			_gradientDict = HeatMapGradientDict.gradientArray(_heatMapTheme);
		}
		
		/**
		 * @private
		 */
		protected function getDetailsCompleteHandler(event:DetailsEvent):void
		{
			_detailsTask.removeEventListener(DetailsEvent.GET_DETAILS_COMPLETE, getDetailsCompleteHandler);
			if (event)
			{
				_layerDetails = event.layerDetails;
			}
			invalidateHeatMap();
			dispatchEvent(event);
		}
		
		/**
		 * @private
		 */
		protected function getDetailsFaultHandler(event:FaultEvent):void
		{
			_detailsTask.removeEventListener(FaultEvent.FAULT, getDetailsFaultHandler);
			dispatchEvent(new LayerEvent(LayerEvent.LOAD_ERROR, this, event.fault));
		}
		
		/**
		 * @private
		 */
		protected function updateStartCompleteHandler(event:LayerEvent):void
		{
			removeEventListener(LayerEvent.UPDATE_START, updateStartCompleteHandler);
			if (map)
			{
				map.addEventListener(ExtentEvent.EXTENT_CHANGE, heatMapExtentChangeHandler);
				map.addEventListener(TimeExtentEvent.TIME_EXTENT_CHANGE, timeExtentChangeHandler);
			}
			_heatMapQueryTask = new QueryTask(_url);
			_heatMapQueryTask.addEventListener(QueryEvent.EXECUTE_COMPLETE, heatMapQueryCompleteHandler, false, 0, true);
			_heatMapQueryTask.addEventListener(FaultEvent.FAULT, heatMapQueryFaultHandler, false, 0, true);
			
		}
		
		/**
		 * @private
		 */
		protected function removeCompleteHandler(event:Event):void
		{
			if (this.map)
			{
				map.removeEventListener(ExtentEvent.EXTENT_CHANGE, heatMapExtentChangeHandler);
				map.removeEventListener(TimeExtentEvent.TIME_EXTENT_CHANGE, timeExtentChangeHandler);
			}
			removeEventListener(Event.REMOVED, removeCompleteHandler);
			_heatMapQueryTask.removeEventListener(QueryEvent.EXECUTE_COMPLETE, heatMapQueryCompleteHandler);
			_heatMapQueryTask.removeEventListener(FaultEvent.FAULT, heatMapQueryFaultHandler);
		}
		
		/**
		 * @private
		 */
		protected function creationCompleteHandler(event:FlexEvent):void
		{
			removeEventListener(FlexEvent.CREATION_COMPLETE, creationCompleteHandler);
			setLoaded(true);
		}
		
		/**
		 * @private
		 */
		protected function invalidateHeatMap():void
		{
			if (map && map.extent)
			{
				generateHeatMap(map.extent);
			}
		}
		
		/**
		 * @private
		 */
		protected function generateHeatMap(extent:Extent):void
		{
			if (_proxyURL)
			{
				_heatMapQueryTask.proxyURL = _proxyURL;
			}
			if (_token)
			{
				_heatMapQueryTask.token = _token;
			}
			_heatMapQueryTask.useAMF = _useAMF;
			if (_where)
			{
				_heatMapQuery.where = _where;
			}
			_heatMapQuery.geometry = extent;
			_heatMapQuery.returnGeometry = true;
			_heatMapQuery.outSpatialReference = map.spatialReference;
			if (_outFields)
			{
				_heatMapQuery.outFields = _outFields;
			}
			else
			{
				_heatMapQuery.outFields = [ '*' ];
			}
			
			if (_timeExtent)
			{
				_heatMapQuery.timeExtent = _timeExtent;
			}
			
			dispatchEvent(new HeatMapEvent(HeatMapEvent.REFRESH_START));
			if (visible)
			{
				_heatMapQueryTask.execute(_heatMapQuery);
			}
		}
		
		/**
		 * @private
		 */
		protected function timeExtentChangeHandler(event:TimeExtentEvent):void
		{
			_timeExtent = event.timeExtent;
			invalidateHeatMap();
		}
		
		/**
		 * @private
		 */
		protected function heatMapExtentChangeHandler(event:ExtentEvent):void
		{
			// Perform the query, when queryComplete occurs call invalidateLayer()
			generateHeatMap(event.extent);
		}
		
		/**
		 * @private
		 */
		protected function heatMapQueryFaultHandler(event:FaultEvent):void
		{
			dispatchEvent(new LayerEvent(LayerEvent.LOAD_ERROR, this, event.fault));
		}
		
		/**
		 * @private
		 */
		protected function heatMapQueryCompleteHandler(event:QueryEvent):void
		{
			if (event)
			{
				dispatchEvent(new HeatMapEvent(HeatMapEvent.REFRESH_END, event.featureSet.features.length, event.featureSet));
				
				_dataProvider = new ArrayList(event.featureSet.features);
				
				setLoaded(true);
				invalidateLayer();
			}
		}
		
		
		
		/**
		 * @private
		 */
		override protected function updateLayer():void
		{
			const mapW:Number = map.width;
			const mapH:Number = map.height;
			const extW:Number = map.extent.width;
			const extH:Number = map.extent.height;
			const facX:Number = mapW / extW;
			const facY:Number = mapH / extH;
			
			if (!_dataProvider)
			{
				return;
			}
			const len:int = _dataProvider.length;
			
			var i:int, feature:Graphic, mapPoint:MapPoint, cluster:Cluster, radius:Number;
			
			if (_bitmapData && (_bitmapData.width !== map.width || _bitmapData.height !== map.height))
			{
				_bitmapData.dispose();
				_bitmapData = null;
			}
			if (_bitmapData === null)
			{
				_bitmapData = new BitmapData(map.width, map.height, true, 0x00000000);
			}
			
			_bitmapData.lock();
			
			_bitmapData.fillRect(_bitmapData.rect, 0x00000000);
			
			if (map.wrapAround180)
			{
				switch (map.spatialReference.wkid)
				{
					case 102113:
					case 102100:
					case 3857:
					{
						_world = 2.0 * 20037508.342788905;
						break;
					}
					case 4326:
					{
						_world = 2.0 * 180.0;
						break;
					}
					default:
					{
						_world = 0.0;
					}
				}
				_wrapAround = doWrapAround;
			}
			else
			{
				_world = 0.0;
				_wrapAround = noWrapAround;
			}
			
			if (_clusterSize)
			{
				if (_center === null)
				{
					_center = map.extent.center;
				}
				var maxWeight:Number = Number.NEGATIVE_INFINITY;
				const cellW:Number = _clusterSize * extW / mapW;
				const cellH:Number = _clusterSize * extH / mapH;
				const clusterDict:Dictionary = new Dictionary();
				for (i = 0; i < len; i++)
				{
					feature = _dataProvider.getItemAt(i) as Graphic;
					mapPoint = feature.geometry as MapPoint;
					if (map.extent.containsXY(mapPoint.x, mapPoint.y))
					{
						const gx:int = Math.floor((mapPoint.x - _center.x) / cellW);
						const gy:int = Math.floor((mapPoint.y - _center.y) / cellH);
						const gk:String = gx + ":" + gy;
						cluster = clusterDict[gk];
						if (cluster === null)
						{
							const cx:Number = gx * cellW + _center.x;
							const cy:Number = gy * cellH + _center.y;
							clusterDict[gk] = cluster = new Cluster(new MapPoint(cx, cy), _clusterWeightCalculator(feature), [ feature ]);
						}
						else
						{
							cluster.graphics.push(feature);
							cluster.weight += _clusterWeightCalculator(feature);
						}
						maxWeight = Math.max(maxWeight, cluster.weight);
					}
				}
				var count:int = 0;
				for each (cluster in clusterDict)
				{
					COLORS[0] = Math.max(0, Math.min(255, _clusterIndexCalculator(cluster, maxWeight)));
					radius = _clusterRadiusCalculator(cluster, _densityRadius, maxWeight);
					_wrapAround(cluster.center);
					count++;
				}
				
				_clusterCount = count;
				dispatchEvent(new Event("clusterCountChanged"));
				
				_clusterMaxWeight = maxWeight;
				dispatchEvent(new Event("clusterMaxWeightChanged"));
			}
			else
			{
				for (i = 0; i < len; i++)
				{
					feature = _dataProvider.getItemAt(i) as Graphic;
					mapPoint = feature.geometry as MapPoint;
					//private const COLORS:Array = [ 0, 0 ];
					COLORS[0] = Math.max(0, Math.min(255, _featureIndexCalculator(feature)));
					//radius:Number
					radius = _featureRadiusCalculator(feature, _densityRadius);
					_wrapAround(mapPoint);
				}
			}
			// paletteMap leaves some artifacts unless we get rid of the blackest colors
			_bitmapData.threshold(_bitmapData, _bitmapData.rect, POINT, "<", 0x00000001, 0x00000000, 0x000000FF, true);
			// Replace the black and blue with the gradient. Blacker pixels will get their new colors from
			// the beginning of the gradientArray and bluer pixels will get their new colors from the end. 
			//comment out the line below if you would like to see the heatmap without the palette applied, will be only blue and black
			_bitmapData.paletteMap(_bitmapData, _bitmapData.rect, POINT, null, null, _gradientDict, null);
			// This blur filter makes the heat map looks quite smooth.
			_bitmapData.applyFilter(_bitmapData, _bitmapData.rect, POINT, BLURFILTER);
			
			_bitmapData.unlock();
			
			_matrix2.tx = parent.scrollRect.x;
			_matrix2.ty = parent.scrollRect.y;
			
			graphics.clear();
			graphics.beginBitmapFill(_bitmapData, _matrix2, false, false);
			graphics.drawRect(parent.scrollRect.x, parent.scrollRect.y, map.width, map.height);
			graphics.endFill();
			
			function noWrapAround(mapPoint:MapPoint):void
			{
				if (map.extent.containsXY(mapPoint.x, mapPoint.y))
				{
					drawXY(mapPoint.x, mapPoint.y);
				}
			}
			
			function doWrapAround(mapPoint:MapPoint):void
			{
				var x:Number = mapPoint.x;
				while (x > map.extent.xmin)
				{
					drawXY(x, mapPoint.y);
					x -= _world;
				}
				x = mapPoint.x + _world;
				while (x < map.extent.xmax)
				{
					drawXY(x, mapPoint.y);
					x += _world;
				}
			}
			
			function drawXY(x:Number, y:Number):void
			{
				const diameter:int = radius + radius;
				
				if(isWind==false)
				{
					_matrix1.createGradientBox(radius1*2, radius1*1, 0, -radius1/12, -radius1/12);
				
					_shape.graphics.clear();
					_shape.graphics.beginGradientFill(GradientType.RADIAL, COLORS, ALPHAS, RATIOS, _matrix1);
					_shape.graphics.drawEllipse(0, 0, radius1*2, radius1);
					_shape.graphics.endFill();
				}
				if(isWind==true)
				{
					_matrix1.createGradientBox(radius1*2, radius1*2, 0, -radius1, -radius1);
					_shape.graphics.clear();
					_shape.graphics.beginGradientFill(GradientType.RADIAL, COLORS, ALPHAS, RATIOS, _matrix1);
					_shape.graphics.drawCircle(0, 0, radius1);
					_shape.graphics.endFill();
				}
				
				_matrix2.tx = Math.floor((x - map.extent.xmin) * facX);   
				_matrix2.ty = Math.floor(mapH - (y - map.extent.ymin) * facY);
				_bitmapData.draw(_shape, _matrix2, null, BlendMode.SCREEN, null, true);
			}
			dispatchEvent(new LayerEvent(LayerEvent.UPDATE_END, this, null, true));
			
		} //end updateLayer
		
		//--------------------------------------
		// Getters and setters 
		//--------------------------------------
		
		//--------------------------------------
		//  url
		//--------------------------------------
		
		[Bindable("urlChanged")]
		/**
		 * URL of the point layer in feature or map service that will be used to generate the heatmap.
		 */
		public function get url():String
		{
			return _url;
		}
		
		/**
		 * @private
		 */
		public function set url(value:String):void
		{
			if (_url != value && value)
			{
				_url = value;
				invalidateHeatMap();
				setLoaded(false);
				dispatchEvent(new Event("urlChanged"));
			}
		}
		
		//--------------------------------------
		//  proxyURL
		//--------------------------------------
		
		/**
		 * The URL to proxy the request through.
		 */
		public function get proxyURL():String
		{
			return _proxyURL;
		}
		
		/**
		 * @private
		 */
		public function set proxyURL(value:String):void
		{
			_proxyURL = value;
		}
		
		//--------------------------------------
		//  token
		//--------------------------------------
		
		[Bindable("tokenChanged")]
		/**
		 * Token for accessing a secure ArcGIS service.
		 *
		 */
		public function get token():String
		{
			return _token;
		}
		
		/**
		 * @private
		 */
		public function set token(value:String):void
		{
			if (_token !== value)
			{
				_token = value;
				dispatchEvent(new Event("tokenChanged"));
			}
		}
		
		//--------------------------------------
		//  useAMF
		//--------------------------------------
		
		[Bindable("useAMFChanged")]
		/**
		 * Use AMF for executing the query. This is the preferred method, but the server must support it.
		 */
		public function get useAMF():Boolean
		{
			return _useAMF;
		}
		
		/**
		 * @private
		 */
		public function set useAMF(value:Boolean):void
		{
			if (_useAMF !== value)
			{
				_useAMF = value;
				dispatchEvent(new Event("useAMFChanged"));
			}
		}
		
		//--------------------------------------
		//  where
		//--------------------------------------
		
		[Bindable("whereChanged")]
		/**
		 * A where clause for the query, refer to the Query class in the ArcGIS API for Flex documentation.
		 * @default 1=1
		 */
		public function get where():String
		{
			return _where;
		}
		
		/**
		 * @private
		 */
		public function set where(value:String):void
		{
			if (_where !== value)
			{
				_where = value;
				invalidateHeatMap();
				dispatchEvent(new Event("whereChanged"));
			}
		}
		
		//--------------------------------------
		//  outFields
		//--------------------------------------
		
		[Bindable("outFieldsChanged")]
		/**
		 * Attribute fields to include in the FeatureSet returned in the HeatMapEvent.
		 */
		public function get outFields():Array
		{
			return _outFields;
		}
		
		/**
		 * @private
		 */
		public function set outFields(value:Array):void
		{
			if (_outFields !== value)
			{
				_outFields = value;
				dispatchEvent(new Event("outFieldsChanged"));
			}
		}
		
		//--------------------------------------
		//  timeExtent
		//--------------------------------------
		
		[Bindable("timeExtentChanged")]
		/**
		 * The time instant or the time extent to query, this is usually set internally
		 * through a time extent change event when the map time changes and not set directly.
		 */
		public function get timeExtent():TimeExtent
		{
			return _timeExtent;
		}
		
		/**
		 * @private
		 */
		public function set timeExtent(value:TimeExtent):void
		{
			if (_timeExtent !== value)
			{
				_timeExtent = value;
				invalidateHeatMap();
				dispatchEvent(new Event("timeExtentChanged"));
			}
		}
		
		//--------------------------------------
		//  theme
		//--------------------------------------
		
		[Bindable("heatMapThemeChanged")]
		/**
		 * The "named" color scheme used to generate the client-side heatmap layer.
		 * @default RAINBOW
		 */
		public function get theme():String
		{
			return _heatMapTheme;
		}
		
		/**
		 * @private
		 */
		public function set theme(value:String):void
		{
			if (_heatMapTheme !== value)
			{
				_heatMapTheme = value;
				_gradientDict = HeatMapGradientDict.gradientArray(_heatMapTheme);
				refresh();
				dispatchEvent(new Event("heatMapThemeChanged"));
			}
		}
		
		/**
		 * Gets the detailed information for the ArcGIS layer used to generate the heatmap.
		 *
		 * @return The <code>LayerDetails</code> of the point layer being queried in the map or feature service.
		 *
		 */
		public function get layerDetails():LayerDetails
		{
			return _layerDetails;
		}
		
		//--------------------------------------------------------------------------
		//
		//  New methods at 3.1
		//
		//--------------------------------------------------------------------------
		
		//--------------------------------------
		//  cluster max weight
		//--------------------------------------
		
		/**
		 * The maximum weight of the cluster.
		 */
		[Bindable("clusterMaxWeightChanged")]
		public function get clusterMaxWeight():Number
		{
			return _clusterMaxWeight;
		}
		
		//--------------------------------------
		//  cluster count
		//--------------------------------------
		
		/**
		 * The cluster count.
		 */
		[Bindable("clusterCountChanged")]
		public function get clusterCount():int
		{
			return _clusterCount;
		}
		
		//--------------------------------------
		//  cluster size
		//--------------------------------------
		
		/**
		 * The cluster size.
		 */
		[Bindable]public function get clusterSize():int
		{
			return _clusterSize;
		}
		
		/**
		 * @private
		 */
		public function set clusterSize(value:int):void
		{
			if (_clusterSize !== value)
			{
				_clusterSize = value;
				invalidateLayer();
			}
		}
		
		//--------------------------------------
		//  density radius
		//--------------------------------------
		
		/**
		 * The density radius.  This controls the size of the heat
		 * radius for a given point.
		 */
		[Bindable]public function get densityRadius():int
		{
			return _densityRadius;
		}
		
		/**
		 * @private
		 */
		public function set densityRadius(value:int):void
		{
			if (_densityRadius !== value)
			{
				_densityRadius = value;
				invalidateLayer();
			}
		}
		
		//--------------------------------------------------------------------------
		//
		//  functions used to manipulate heatmap generation
		//
		//--------------------------------------------------------------------------
		
		/**
		 * The function to use to calculate the density radius.
		 * If not set the heatmap layer will default to the internal function.
		 */
		[Bindable("featureRadiusCalculatorChanged")]
		public function set featureRadiusCalculator(value:Function):void
		{
			_featureRadiusCalculator = value === null ? internalFeatureRadiusCalculator : value;
			invalidateLayer();
		}
		
		/**
		 * The function to use to calculate the index used to retrieve colors from
		 * the gradient dictionary.
		 * If not set the heatmap layer will default to the internal function.
		 */
		[Bindable("featureIndexCalculatorChanged")]
		public function set featureIndexCalculator(value:Function):void
		{
			_featureIndexCalculator = value === null ? internalFeatureCalculator : value;
			invalidateLayer();
		}
		
		/**
		 * The function to use to calculate the cluster radius.
		 * If not set the heatmap layer will default to the internal function.
		 */
		[Bindable("clusterRadiusCalculatorChanged")]
		public function set clusterRadiusCalculator(value:Function):void
		{
			_clusterRadiusCalculator = value === null ? internalClusterRadiusCalculator : value;
			invalidateLayer();
		}
		
		/**
		 * The function to use to calculate the cluster index.
		 * If not set the heatmap layer will default to the internal function.
		 */
		[Bindable("clusterIndexCalculatorChanged")]
		public function set clusterIndexCalculator(value:Function):void
		{
			_clusterIndexCalculator = value === null ? internalClusterCalculator : value;
			invalidateLayer();
		}
		
		/**
		 * The function to use to calculate the cluster weight.
		 * If not set the heatmap layer will default to the internal function.
		 */
		[Bindable("clusterWeightCalculatorChanged")]
		public function set clusterWeightCalculator(value:Function):void
		{
			_clusterWeightCalculator = value === null ? internalWeightCalculator : value;
			invalidateLayer();
		}
		
		private function internalWeightCalculator(feature:Graphic):Number
		{
			return 1.0;
		}
		
		private function internalFeatureCalculator(feature:Graphic):int
		{
			return 255;
		}
		
		private function internalClusterCalculator(cluster:Cluster, weightMax:Number):int
		{
			return 255 * cluster.weight / weightMax;
		}
		
		private function internalFeatureRadiusCalculator(feature:Graphic, radius:Number):Number
		{
			return radius;
		}
		
		private function internalClusterRadiusCalculator(cluster:Cluster, radius:Number, weightMax:Number):Number
		{
			return radius;
		}
		
	} //end class
}
