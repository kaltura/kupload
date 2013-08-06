package com.kaltura.upload.commands
{
	import com.kaltura.upload.errors.KsuError;
	import com.kaltura.upload.vo.FileFilterVO;

	public class SetMediaTypeCommand extends BaseUploadCommand
	{
		private var _mediaType:String;

		public function SetMediaTypeCommand(mediaType:String)
		{
			_mediaType = mediaType;
		}

		override public function execute():void
		{
			var fileFilterVo:FileFilterVO = model.fileFilterVoList[_mediaType];
			trace('change media type: ' +  _mediaType);
			if (fileFilterVo)
			{
				model.activeFileFilterVO = fileFilterVo;
				model.selectedFileFilterArr = new Array(model.activeFileFilterVO);
			}
			else
			{
				throw new KsuError("No such file filter id: " + _mediaType, KsuError.MISSING_FILTER_FOR_MEDIA_TYPE);
			}
		}

	}
}