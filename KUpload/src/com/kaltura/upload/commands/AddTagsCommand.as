package com.kaltura.upload.commands
{
	import com.kaltura.upload.vo.FileVO;

	import flash.errors.IOError;

	public class AddTagsCommand extends BaseUploadCommand
	{
		private var _tags:Array;
		private var _startIndex:int;
		private var _endIndex:int;

		public function AddTagsCommand(tags:Array, startIndex:int, endIndex:int):void
		{
			_tags = tags;
			_startIndex = startIndex;
			_endIndex = endIndex;
		}

		override public function execute():void
		{
			for (var i:int = _startIndex; i < _endIndex + 1 ; i++)
			{
				var fileVo:FileVO = model.files[i];
				if (!fileVo)
					throw new Error("Can not add tags, file with index " + i + " does not exist");
				fileVo.tags = fileVo.tags.concat(_tags);
			}
		}
	}
}