package com.kaltura.upload.events
{
	import flash.events.Event;

	public class KUploadEvent extends Event
	{
		public static const ERROR:String = "error";
		public static const READY:String = "ready";
		public static const SELECT:String = "select";
		public static const SINGLE_UPLOAD_COMPLETE:String = "singleUploadComplete";
		public static const ALL_UPLOADS_COMPLETE:String = "allUploadsComplete";
		public static const ENTRIES_ADDED:String = "entriesAdded";

		public static const PROGRESS:String = "progress";

		public function KUploadEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}