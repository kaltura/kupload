package com.kaltura.upload.commands
{
	import com.kaltura.upload.controller.KUploadController;
	import com.kaltura.upload.vo.FileVO;
	
	import flash.external.ExternalInterface;
	import flash.net.FileReference;

	public class NotifyShellCommand extends BaseUploadCommand
	{
		private var _eventName:String;
		private var _args:Array;

		public function NotifyShellCommand(eventName:String, arguments:Array = null):void
		{
			_eventName = eventName;
			_args = arguments;
		}

		override public function execute():void
		{
			var delegate:String = model.jsDelegate;
			var callbackName:String = _eventName + "Handler";
			var fullExpression:String = delegate + "." + callbackName;
			trace('execute NotifyShellCommand with event: ' + _eventName);
			if(model.externalInterfaceEnable)
			{
				/*var jsArgs:Array = _args ? new Array() : null;
				for each(var arg:Object in _args)
					jsArgs.push(arg is FileVO ? (arg as FileVO).file.fileReference : arg);*/
					
				ExternalInterface.call(fullExpression, _args);
			}
			KUploadController.getInstance().getApp().dispatchActionEvent(fullExpression, _args);
		}
	}
}