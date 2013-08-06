package com.kaltura.upload.commands
{
	import com.kaltura.upload.errors.KsuError;

	public class RemoveFilesCommand extends BaseUploadCommand
	{
		private var _startIndex:int;
		private var _endIndex:int;

		public function RemoveFilesCommand(startIndex:int, endIndex:int):void
		{
			_startIndex = startIndex;
			_endIndex = endIndex;
		}

		override public function execute():void
		{
			var deleteCount:int = _endIndex - _startIndex + 1;
			if (deleteCount <= 0)
				throw new KsuError("Files delete count (" + deleteCount + ") is not valid.", KsuError.FILES_RANGE_ERROR);
			else if (!model.files[_startIndex] || !model.files[_endIndex])
				throw new KsuError("Delete range error", KsuError.FILES_RANGE_ERROR);
			model.files.splice( _startIndex, deleteCount);

			var validateLimitationsCommand:ValidateLimitationsCommand = new ValidateLimitationsCommand();
			validateLimitationsCommand.execute();
		}

	}
}