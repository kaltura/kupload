package com.kaltura.upload.events
{
	import flash.events.Event;

	public class KUploadErrorEvent extends Event
	{
		public static const KS_ERRORS:String = "ksErrors";
		public static const UPLOAD_ERROR:String = "uploadError";
		public static const ADD_ENTRY_FAILED:String = "addEntryFailed";
		public static const UI_CONF_ERROR:String = "uiConfError";


		public static const FILE_SIZE_EXCEEDS:String 	= "fileSizeExceeds";
		public static const TOTAL_SIZE_EXCEEDS:String 	= "totalSizeExceeds";
		public static const NUM_FILES_EXCEEDS:String 	= "numFilesExceeds";

		public function KUploadErrorEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
	}
}