package com.kaltura.upload.commands
{
	import com.kaltura.upload.controller.KUploadController;
	
	import flash.external.ExternalInterface;

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
				ExternalInterface.call(fullExpression, _args);
			}
			KUploadController.getInstance().getApp().dispatchActionEvent(fullExpression, _args);
		}
	}
}