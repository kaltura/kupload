package com.kaltura.upload.controller
{
	public class KUploadController
	{
		private static var _instance:KUploadController = null;
		private var _kUpload:KUpload;
		
		public function KUploadController(enforcer:Enforcer){}
		
		public static function getInstance():KUploadController
		{
			if(_instance == null)
			{
				_instance = new KUploadController(new Enforcer());
			}
			return _instance;
		}
		
		public function registerApp(loader:KUpload):void
		{
			_kUpload = loader;
		}
		
		public function getApp():KUpload
		{
			return _kUpload;
		}

	}
}

class Enforcer
{
	
}