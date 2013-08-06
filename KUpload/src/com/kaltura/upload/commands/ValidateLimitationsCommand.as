package com.kaltura.upload.commands
{
	import com.kaltura.upload.events.KUploadErrorEvent;
	import com.kaltura.upload.events.KUploadEvent;
	import com.kaltura.upload.vo.FileVO;

	public class ValidateLimitationsCommand extends BaseUploadCommand
	{
		override public function execute():void
		{
			if (fileSizeExceeds())
			{
				model.error = KUploadErrorEvent.FILE_SIZE_EXCEEDS;
				notifyErrorToShell();
				return;
			}
			else if (totalSizeExceeds())
			{
				model.error = KUploadErrorEvent.TOTAL_SIZE_EXCEEDS;
				notifyErrorToShell();
				return; 
			}
			else if (numFilesExceeds())
			{
				model.error = KUploadErrorEvent.NUM_FILES_EXCEEDS;
				notifyErrorToShell();
				return;
			}
			
			model.error = null;
		}
		
		private function notifyErrorToShell():void
		{
				//handle general validation error and notify the error type to the shell 
				var notifyShell:NotifyShellCommand = new NotifyShellCommand(KUploadEvent.ERROR ,  [model.error] );
				notifyShell.execute(); 
		}

		private function fileSizeExceeds():Boolean
		{
			var files:Array = model.files;
			var exceedingFiles:Array = [];
			files.forEach(
				function(fileVo:FileVO, i:int, list:Array):void
				{
					// if file is larger than 4G, fileVo.bytesTotal = 0  
					if (fileVo.bytesTotal == 0 || fileVo.bytesTotal > model.maxFileSize * 1e6)
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