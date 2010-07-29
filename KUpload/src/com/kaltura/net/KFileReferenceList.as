package com.kaltura.net
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.FileReferenceList;

	[Event(name="cancel", type="flash.events.Event")]
	[Event(name="select", type="flash.events.Event")]
	public class KFileReferenceList extends EventDispatcher
	{
		private var _fileReferenceList:FileReferenceList;
		private var _fileList:Array;

		public function KFileReferenceList()
		{
			_fileReferenceList = new FileReferenceList();
			_fileReferenceList.addEventListener(Event.SELECT, fileReferenceListSelectHandler);
		}

		public function get fileList():Array /*of FileReference*/
		{
			return _fileList;
		}

		public function browse(typeFilter:Array = null, singleFile:Boolean = false):Boolean
		{
			_fileReferenceList.browse(typeFilter);
		}

		private function fileReferenceListSelectHandler(selectEvent:Event):void
		{
			_fileList = _fileReferenceList.fileList;
			dispatchEvent(new Event(Event.SELECT));
		}
	}
}