package com.kaltura.upload.commands
{
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
				throw new Error("Files delete count (" + deleteCount + ") is not valid.");
			else if (!model.files[_startIndex] || !model.files[_endIndex])
				throw new Error("Delete range error");
			model.files.splice( _startIndex, deleteCount);

			var validateLimitationsCommand:ValidateLimitationsCommand = new ValidateLimitationsCommand();
			validateLimitationsCommand.execute();
		}

	}
}