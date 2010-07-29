package com.kaltura.upload.events
{
	import flash.events.Event;
	
	public class ActionEvent extends Event
	{
		public var args:Array;
		public function ActionEvent(type:String, args:Array, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
			this.args = args;
		}
		
		
	}
}