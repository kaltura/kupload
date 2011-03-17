package com.kaltura.upload.vo
{
	import com.kaltura.net.PolledFileReference;
	import com.kaltura.vo.importees.UploadStatusTypes;
	
	import flash.events.Event;
	import flash.events.ProgressEvent;

	public class FileVO
	{
		private static var uniquenessCounter:int;

		public function FileVO():void
		{
			uniquenessCounter++;
			guid = new Date().time.toString() + uniquenessCounter.toString();
		}
		public var bytesLoaded:uint;
		public var bytesTotal:uint
		public var title:String
		public var tags:Array = [];
		public var guid:String;
		public var extension:String;
		public var mediaTypeCode:String;
		public var entryType:String;
		public var entryId:String;
		public var uploadStatus:String = UploadStatusTypes.NOT_UPLOADED;
		public var thumbnailUrl:String;
		public var token:String;

		public function set file(value:PolledFileReference):void
		{
			removeFileListeners();

			_file = value;
			bytesTotal = _file.fileReference.size;

			addFileListeners();
		}
		public function get file():PolledFileReference
		{
			return _file;
		}
		private var _file:PolledFileReference;


		private function addFileListeners():void
		{
			_file.addEventListener(ProgressEvent.PROGRESS, 		fileProgressHandler);
			_file.addEventListener(Event.CANCEL, 				fileCancelHandler);
			_file.addEventListener(Event.COMPLETE, 				fileCompleteHandler);
		}

		private function removeFileListeners():void
		{
			if (!_file) return;
			_file.removeEventListener(ProgressEvent.PROGRESS, 	fileProgressHandler);
			_file.removeEventListener(Event.CANCEL, 			fileCancelHandler);
		}

		private function fileProgressHandler(progressEvent:ProgressEvent):void
		{
			bytesLoaded = progressEvent.bytesLoaded;
		}

		private function fileCancelHandler(cancelEvent:Event):void
		{
			bytesLoaded = 0;
		}

		private function fileCompleteHandler(completeEvent:Event):void
		{
			bytesLoaded = bytesTotal;
		}
	}
}