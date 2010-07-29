package com.kaltura.upload.commands
{
	import com.kaltura.upload.model.KUploadModelLocator;

	import flash.events.EventDispatcher;

	public class BaseUploadCommand extends EventDispatcher
	{
		protected var model:KUploadModelLocator = KUploadModelLocator.getInstance();
		public function execute():void
		{
		}

	}
}