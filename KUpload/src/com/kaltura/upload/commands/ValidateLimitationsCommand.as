package com.kaltura.upload.commands
{
	import com.kaltura.upload.events.KUploadErrorEvent;
	import com.kaltura.upload.vo.FileVO;

	public class ValidateLimitationsCommand extends BaseUploadCommand
	{
		override public function execute():void
		{
			if (fileSizeExceeds())
			{
				model.error = KUploadErrorEvent.FILE_SIZE_EXCEEDS;
				return;
			}
			else if (totalSizeExceeds())
			{
				model.error = KUploadErrorEvent.TOTAL_SIZE_EXCEEDS;
				return;
			}
			else if (numFilesExceeds())
			{
				model.error = KUploadErrorEvent.NUM_FILES_EXCEEDS;
				return;
			}
			model.error = null;
		}

		private function fileSizeExceeds():Boolean
		{
			var files:Array = model.files;
			var exceedingFiles:Array = [];
			files.forEach(
				function(fileVo:FileVO, i:int, list:Array):void
				{
					if (fileVo.bytesTotal > model.maxFileSize * 1e6)
						exceedingFiles.push(i);
				}
			);
			model.exceedingFilesIndices = exceedingFiles;
			return exceedingFiles.length > 0;
		}

		private function totalSizeExceeds():Boolean
		{
			return model.totalSize > model.maxTotalSize * 1e6;
		}

		private function numFilesExceeds():Boolean
		{
			return model.files.length > model.maxUploads;
		}

	}
}