package com.kaltura.upload.commands
{
	import com.kaltura.upload.vo.FileVO;

	public class StopUploadsCommand extends BaseUploadCommand
	{
		override public function execute():void
		{
			model.currentlyUploadedFileVo.file.cancel();
			model.currentlyUploadedFileVo = null;
		}
	}
}