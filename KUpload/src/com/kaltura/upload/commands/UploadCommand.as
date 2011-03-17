package com.kaltura.upload.commands
{
	import com.kaltura.commands.uploadToken.UploadTokenAdd;
	import com.kaltura.commands.uploadToken.UploadTokenUpload;
	import com.kaltura.events.KalturaEvent;
	import com.kaltura.net.PolledFileReference;
	import com.kaltura.net.TemplateURLVariables;
	import com.kaltura.upload.events.KUploadErrorEvent;
	import com.kaltura.upload.events.KUploadEvent;
	import com.kaltura.upload.vo.FileVO;
	import com.kaltura.vo.KalturaUploadToken;
	import com.kaltura.vo.importees.UploadStatusTypes;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;

	public class UploadCommand extends BaseUploadCommand
	{
		private var _activeFile:FileVO;
		private var _files:Array; /*of FileVO*/

		override public function execute():void
		{

			if (model.error == KUploadErrorEvent.FILE_SIZE_EXCEEDS ||
				model.error == KUploadErrorEvent.TOTAL_SIZE_EXCEEDS ||
				model.error == KUploadErrorEvent.NUM_FILES_EXCEEDS)
			{
				throw new Error("Cannot upload, limitations exceeded:" + model.error + ". Please check for errors");
				return;
			}
			trace('upload selected file(s)');
			_files = getNotUploadedFiles();
			uploadNextFile();
		}

		private function uploadNextFile():void
		{
			if (_files.length > 0)
			{
				_activeFile = _files.shift();
				model.currentlyUploadedFileVo = _activeFile;
				
				var fileToken:KalturaUploadToken = new KalturaUploadToken();
				fileToken.fileName = _activeFile.file.fileReference.name;
				fileToken.fileSize = _activeFile.file.bytesTotal;
				var uploadToken:UploadTokenAdd = new UploadTokenAdd(fileToken);
				uploadToken.addEventListener(KalturaEvent.COMPLETE, uploadTokenAddHandler);
				uploadToken.addEventListener(KalturaEvent.FAILED, onFileFailed);
				
				model.context.kc.post(uploadToken);
			}
			else
			{
				allFilesComplete()
			}
		}
		
		/**
		 * file token was added, now upload the file
		 * */
		private function uploadTokenAddHandler(event:KalturaEvent):void {
			var tokenId:String = (event.data as KalturaUploadToken).id;
			_activeFile.token = tokenId;
			var uploadFile:UploadTokenUpload = new UploadTokenUpload(tokenId, _activeFile.file.fileReference);
			uploadFile.addEventListener(KalturaEvent.COMPLETE, fileCompleteHandler);
			uploadFile.addEventListener(KalturaEvent.FAILED, onFileFailed);
			
			model.context.kc.post(uploadFile);
		}
		
		/**
		 * file finished uploading
		 * */
		private function fileCompleteHandler(event:KalturaEvent):void
		{
			trace('finish uploading selected file(s)');
			_activeFile.uploadStatus = UploadStatusTypes.UPLOAD_COMPLETE;
			uploadNextFile();
		}
		
		/**
		 * upload error
		 * */
		private function onFileFailed(info:Object):void {
			_activeFile.uploadStatus = UploadStatusTypes.UPLOAD_FAILED;
			uploadNextFile();
		}

		private function onFileComplete(evtComplete:Event):void
		{
			var notifyShell:NotifyShellCommand = new NotifyShellCommand(KUploadEvent.SINGLE_UPLOAD_COMPLETE, [_activeFile]);
			notifyShell.execute();

			uploadNextFile();
		}

	
		private function fileOpenHandler(openEvent:Event):void
		{
			//report the progress because if the upload is fast, the 0 bytes out of X progress event doesn't always dispatched
			var notifyShell:NotifyShellCommand = new NotifyShellCommand(KUploadEvent.PROGRESS, [0, _activeFile.bytesTotal, _activeFile]);
			notifyShell.execute();

		}
		private function fileProgressHandler(progressEvent:ProgressEvent):void
		{
			var notifyShell:NotifyShellCommand = new NotifyShellCommand(KUploadEvent.PROGRESS, [progressEvent.bytesLoaded, progressEvent.bytesTotal, _activeFile]);
			notifyShell.execute();
		}

		private function getURLVariables(fileVO:FileVO):URLVariables
		{
			var uploadURLVariables:TemplateURLVariables = new TemplateURLVariables(model.baseRequestData);
			uploadURLVariables["filename"] = fileVO.guid;
			return uploadURLVariables;
		}

		private function allFilesComplete():void
		{
			trace("all uploads complete" );

			var validateUploads:ValidateUploadCommand = new ValidateUploadCommand();
			validateUploads.execute();

			var notifyShell:NotifyShellCommand = new NotifyShellCommand(KUploadEvent.ALL_UPLOADS_COMPLETE);
			notifyShell.execute();
		}

		private function getNotUploadedFiles():Array
		{
			return model.files.filter(
				function(fileVo:FileVO, i:int, list:Array):Boolean
				{
					return fileVo.bytesLoaded < fileVo.bytesTotal;
				}
			)
		}
	}
}