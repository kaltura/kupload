package com.kaltura.upload.commands
{
	import com.kaltura.upload.business.PartnerNotificationVO;
	import com.kaltura.upload.events.KUploadEvent;

	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	public class SendNotificationsCommand extends BaseUploadCommand
	{
		private static const TIMEOUT:int = 30e3;

		private var _requestsLeft:int;

		private var _timeoutId:uint;
		private var _notifications:Array;

		public function SendNotificationsCommand(notificationVoList:Array):void
		{
			_notifications = notificationVoList;
		}

		override public function execute():void
		{
			_requestsLeft = _notifications.length;
			_notifications.forEach(sendNotification);
			_timeoutId = setTimeout(sendNotificationsComplete, TIMEOUT);
		}

		private function sendNotification(partnerNotificationVo:PartnerNotificationVO, index:int, list:Array):void
		{
			var urlLoader:URLLoader = new URLLoader();
			var requestData:URLVariables = new URLVariables(partnerNotificationVo.queryString);
			var request:URLRequest = new URLRequest(partnerNotificationVo.url);
			request.data = requestData;
			request.method = URLRequestMethod.POST;
			urlLoader.addEventListener(Event.COMPLETE, 			loaderCompleteHandler);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR,	ioErrorHandler);
			urlLoader.load(request);

		}

		private function loaderCompleteHandler(completeEvent:Event):void
		{
			notificationSent();
		}


		private function ioErrorHandler(ioErrorEvent:Event):void
		{
			trace("send notifications io error");
			notificationSent();
		}

		private function dispose():void
		{
			clearTimeout(_timeoutId);
		}

		private function notificationSent():void
		{
			if (--_requestsLeft == 0)
			{
				sendNotificationsComplete();
			}
		}

		private function sendNotificationsComplete():void
		{
			dispose();
			var notifyShell:NotifyShellCommand = new NotifyShellCommand(KUploadEvent.ENTRIES_ADDED, model.files);
	   		notifyShell.execute();
		}

	}
}