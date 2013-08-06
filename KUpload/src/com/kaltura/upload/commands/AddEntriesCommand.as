package com.kaltura.upload.commands
{
	import com.kaltura.KalturaClient;
	import com.kaltura.commands.MultiRequest;
	import com.kaltura.commands.baseEntry.BaseEntryAddFromUploadedFile;
	import com.kaltura.commands.media.MediaAddFromUploadedFile;
	import com.kaltura.commands.notification.NotificationGetClientNotification;
	import com.kaltura.events.KalturaEvent;
	import com.kaltura.types.KalturaMediaType;
	import com.kaltura.types.KalturaNotificationType;
	import com.kaltura.upload.business.PartnerNotificationVO;
	import com.kaltura.upload.errors.KsuError;
	import com.kaltura.upload.events.KUploadErrorEvent;
	import com.kaltura.upload.events.KUploadEvent;
	import com.kaltura.upload.vo.FileVO;
	import com.kaltura.vo.KalturaBaseEntry;
	import com.kaltura.vo.KalturaClientNotification;
	import com.kaltura.vo.KalturaMediaEntry;
	
	import flash.events.Event;

	public class AddEntriesCommand extends BaseUploadCommand
	{

		public function AddEntriesCommand():void
		{
		}
		
		override public function execute():void
		{
			if (model.error)
			{
				throw new KsuError("Cannot add entries, some uploads failed. Either re-upload or remove the files", KsuError.CANNOT_ADD_ENTRIES);
				return;
			}
			var mr:MultiRequest = new MultiRequest();
			var requestIndex:int = 1;
			for each (var fileVo:FileVO in model.files) {
				//media entry
				if (fileVo.mediaTypeCode && (
					(fileVo.mediaTypeCode == KalturaMediaType.AUDIO.toString()) 
					|| (fileVo.mediaTypeCode == KalturaMediaType.VIDEO.toString())
					|| (fileVo.mediaTypeCode == KalturaMediaType.IMAGE.toString()))) 
				{
					var mediaEntry:KalturaMediaEntry = new KalturaMediaEntry();
					mediaEntry.mediaType = parseInt(fileVo.mediaTypeCode);
					updateKalturaBaseEntry(fileVo, mediaEntry as KalturaBaseEntry);
					var addMediaEntry:MediaAddFromUploadedFile = new MediaAddFromUploadedFile(mediaEntry, fileVo.token);
					mr.addAction(addMediaEntry);
				}
				//base entry
				else
				{
					var kalturaEntry:KalturaBaseEntry = new KalturaBaseEntry();
					updateKalturaBaseEntry(fileVo, kalturaEntry);
					var addEntry:BaseEntryAddFromUploadedFile = new BaseEntryAddFromUploadedFile (kalturaEntry, fileVo.token, fileVo.entryType);
					mr.addAction(addEntry);
				}
				requestIndex++;
				//get notifications for entry
				var getNotification:NotificationGetClientNotification = new NotificationGetClientNotification('entryId', KalturaNotificationType.ENTRY_ADD);
				mr.mapMultiRequestParam(requestIndex - 1, 'id', requestIndex, 'entryId')
				mr.addAction(getNotification);
				requestIndex++;
			}

			mr.addEventListener(KalturaEvent.COMPLETE, result);
			mr.addEventListener(KalturaEvent.FAILED, fault);
			
			model.context.kc.post(mr);
		}
		
		/**
		 * updates the given  KalturaBaseEntry according to the given fileVO
		 * @param fileVo the given FileVO
		 * @param kalturaBaseEntry the given baseEntry
		 * @return kalturaBaseEntry
		 * 
		 */		
		private function updateKalturaBaseEntry(fileVo:FileVO, kalturaBaseEntry:KalturaBaseEntry):void {
			kalturaBaseEntry.name	= fileVo.title;
			kalturaBaseEntry.creditUserName = model.screenName;
			kalturaBaseEntry.creditUrl = model.siteUrl;
			
			// Ignoring letter capitalization in the file's extension.
			var lowered:String = fileVo.extension.toLowerCase();
			if (model.conversionMapping != null && model.conversionMapping[lowered] != null){
				kalturaBaseEntry.conversionQuality = model.conversionMapping[lowered];
				kalturaBaseEntry.conversionProfileId = parseInt(model.conversionMapping[lowered]);
			} else {
				kalturaBaseEntry.conversionQuality = model.conversionProfile;
				kalturaBaseEntry.conversionProfileId = parseInt(model.conversionProfile);
			}
			
			kalturaBaseEntry.userId = model.context.userId;
			
			if (fileVo.tags.length > 0)
				kalturaBaseEntry.tags	= fileVo.tags.join(",");
			
			if (model.context.partnerData)
				kalturaBaseEntry.partnerData = model.context.partnerData;
			
			if (model.context.groupId)
				kalturaBaseEntry.groupId = parseInt(model.context.groupId);
		}
		
		/**
		 * handle result for "addentries" multirequest
		 * */
		private function result (event:KalturaEvent) : void {
			var resultArray:Array = event.data as Array;
			var notificationsArray:Array = new Array();
			for (var i:int = 0; i< resultArray.length; i++) {
				if (resultArray[i] is KalturaBaseEntry) {
					var entry:KalturaBaseEntry = resultArray[i] as KalturaBaseEntry;
					//location in model.files is always /2 since we also count here the notification requests
					(model.files[i/2] as FileVO).entryId = entry.id;
					(model.files[i/2] as FileVO).thumbnailUrl = entry.thumbnailUrl;
				} 
				else {
					dispatchAddEntryError();
				}
				//following response is for the get notofication request
				i++;
				if (resultArray[i] is KalturaClientNotification) {
					var notification:KalturaClientNotification = (resultArray[i] as KalturaClientNotification);
					var partnerNot:PartnerNotificationVO = new PartnerNotificationVO(notification.url, notification.data );
					notificationsArray.push(partnerNot);
				}
			}
			//handle notifications
			if (notificationsArray.length > 0)
			{
				var sendNotifications:SendNotificationsCommand = new SendNotificationsCommand(notificationsArray);
				sendNotifications.execute();
			}
			else
			{
				var notifyShell:NotifyShellCommand = new NotifyShellCommand(KUploadEvent.ENTRIES_ADDED, model.files);
				notifyShell.execute();
				//clear already added files
				model.files = [];
			}
			
			
		
		}
		
		private function fault (info:Object) : void {
			dispatchAddEntryError();
		}

	 	private function dispatchAddEntryError():void
		{
			var notifyShell:NotifyShellCommand = new NotifyShellCommand(KUploadErrorEvent.ADD_ENTRY_FAILED);
			notifyShell.execute();
		}
	}
}