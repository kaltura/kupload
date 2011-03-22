package com.kaltura.upload.model
{
	import com.kaltura.upload.vo.FileFilterVO;
	import com.kaltura.upload.vo.FileVO;
	
	import flash.utils.Dictionary;

	public class KUploadModelLocator
	{
		//Singleton implementation
		//---------------------------------
		include "SingletonImpl.as"
		//---------------------------------

		public var context:Context = new Context();
		
		//Basic parameters
		public var ks:String;
		public var uid:String;
		public var uiConfId:String;
		public var partnerId:String;
		public var subPId:String;
		public var externalInterfaceEnable:Boolean;
		public var host:String = "http://www.kaltura.com";


		public var screenName:String;
		public var siteUrl:String;

		//deprecated 
		public var quickEdit:Boolean = true;
		public var uploadUrl:String;
		public var uploadHost:String
		public var entryId:String = "-1";
		public var fileFilterVoList:Dictionary; /*of FileFilterVO, key: file filter id*/
		public var fileFiltersArr:Array;
		public var selectedFileFilterArr:Array;
		public var activeFileFilterVO:FileFilterVO;
		public var jsDelegate:String;

		public var baseRequestData:Object;

		public var state:String;


		public var maxFileSize:Number;
		public var maxTotalSize:Number;
		public var maxUploads:uint;

		public var conversionProfile:String;

		public var files:Array = []; /*of FileVO*/

		public var currentlyUploadedFileVo:FileVO;

		public function get totalSize():uint
		{
			var totalKb:uint;

			files.forEach
			(
				function(fileVo:FileVO, i:int, ar:Array):void
				{
					totalKb += fileVo.file.fileReference.size;
				}
			);
			return totalKb;
		}

		public var uploadedErrorIndices:Array;

		public var error:String;
		public var exceedingFilesIndices:Array;


	}
}