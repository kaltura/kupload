package com.kaltura.upload.vo
{
	import flash.net.FileFilter;

	public class FileFilterVO
	{
		public function FileFilterVO(fileFilter:FileFilter, mediaType:String, entryType:String):void
		{
			this.fileFilter = fileFilter;
			this.entryType = entryType;
			this.mediaType = mediaType;
		}
		public var fileFilter:FileFilter;
		public var entryType:String;
		public var mediaType:String;
	}
}