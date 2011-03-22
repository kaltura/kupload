package com.kaltura.upload.commands
{
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
				setFiltersOrder();
			}
			else
			{
				throw new Error("No such file filter id: " + _mediaType);
			}
		}
		
		private function setFiltersOrder():void
		{
			var fileFilters:Array = new Array();
			var fileFilterVo:FileFilterVO = model.activeFileFilterVO;
			for each(var ffVo:FileFilterVO in model.fileFiltersArr)
			{
				if(ffVo.mediaType == fileFilterVo.mediaType)
				{
					fileFilters.push(ffVo);
					break;
				}
			}
			
			/* for each(var ffVo1:FileFilterVO in model.fileFiltersArr)
			{
				if(ffVo1.mediaType != fileFilterVo.mediaType)
				{
					fileFilters.push(ffVo1);
				}
			} */
			
			model.selectedFileFilterArr = fileFilters;
		}

	}
}