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
	
	import com.esri.ags.SpatialReference;
	import com.esri.ags.geometry.MapPoint;
	
	/**
	 * A location to be used in calculating the ArcGISHeatMapLayer.
	 *
	 */
	public class HeatMapPoint extends MapPoint
	{
		
		public var weight:Number;
		
		/**
		 * Creates a new MapPoint object.
		 *
		 * @param x The x-coordinate.
		 * @param y The y-coordinate.
		 * @param weight
		 * @param spatialReference The spatial reference of the point.
		 */
		public function HeatMapPoint(x:Number = 0, y:Number = 0, weight:Number = 1.0, spatialReference:SpatialReference = null)
		{
			super(x, y, spatialReference);
			this.weight = weight;
		}
	}
}
