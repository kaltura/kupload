package com.kaltura.upload.commands
{
	import com.kaltura.net.PolledFileReference;
	import com.kaltura.net.TemplateURLVariables;
	import com.kaltura.upload.events.KUploadErrorEvent;
	import com.kaltura.upload.events.KUploadEvent;
	import com.kaltura.upload.vo.FileVO;
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

				setupFileListeners(_activeFile.file);
				var uploadUrl:String = (model.uploadUrl != null) ? model.uploadUrl : model.serviceUrl;				
				var uploadRequest:URLRequest = new URLRequest(uploadUrl);
				uploadRequest.method = URLRequestMethod.POST;
				uploadRequest.data = getURLVariables(_activeFile);
				_activeFile.file.fileReference.upload(uploadRequest);
			}
			else
			{
				allFilesComplete()
			}
		}

		private function fileCompleteHandler(e:Event):void
		{
			trace('finish uploading selected file(s)');
			_activeFile.uploadStatus = UploadStatusTypes.UPLOAD_COMPLETE;
			uploadNextFile();
		}


		private function setupFileListeners(file:PolledFileReference):void
		{
			file.fileReference.addEventListener(Event.COMPLETE, 							onFileComplete);
			//file.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, 				onUploadCompleteData);
			file.fileReference.addEventListener(IOErrorEvent.IO_ERROR, 						onIoError );
			file.fileReference.addEventListener(SecurityErrorEvent.SECURITY_ERROR, 			onSecurityError);
			file.fileReference.addEventListener(ProgressEvent.PROGRESS, 					fileProgressHandler);
			file.fileReference.addEventListener(Event.OPEN, 								fileOpenHandler);
			file.addEventListener(Event.CANCEL,												polledFileReferenceCancelHandler);
		}

		private function removeFileListeners():void
		{
			_activeFile.file.fileReference.removeEventListener(Event.COMPLETE, 					onFileComplete);
			//_importFileVO.polledfileReference.fileReference.removeEventListener(DataEvent.UPLOAD_COMPLETE_DATA, 	onUploadCompleteData);
			_activeFile.file.fileReference.removeEventListener(IOErrorEvent.IO_ERROR, 				onIoError );
			_activeFile.file.fileReference.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,	onSecurityError);
			_activeFile.file.fileReference.removeEventListener(Event.OPEN, 							fileOpenHandler);
			_activeFile.file.fileReference.removeEventListener(ProgressEvent.PROGRESS, 				fileProgressHandler);
			_activeFile.file.removeEventListener(Event.CANCEL,										polledFileReferenceCancelHandler);
		}

		//FileReference handlers:

		private function onFileComplete(evtComplete:Event):void
		{
			var notifyShell:NotifyShellCommand = new NotifyShellCommand(KUploadEvent.SINGLE_UPLOAD_COMPLETE, [_activeFile]);
			notifyShell.execute();

			removeFileListeners();
			uploadNextFile();
		}

		private function onIoError(evtIoError:IOErrorEvent):void
		{
			removeFileListeners();
			_activeFile.uploadStatus = UploadStatusTypes.UPLOAD_FAILED;
			uploadNextFile();
		}

		private function onSecurityError(evtSecurityError:SecurityErrorEvent):void
		{
			removeFileListeners();
			_activeFile.uploadStatus = UploadStatusTypes.UPLOAD_FAILED;
			uploadNextFile();
		}

		private function polledFileReferenceCancelHandler(evtCancel:Event):void
		{
			removeFileListeners();
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
		
	/* 	private function getProxyURLVariables(fileVO:FileVO):URLVariables
		{
			var uploadURLVariables:TemplateURLVariables = new TemplateURLVariables(new Object());
			uploadURLVariables["filename"] = fileVO.title;
			return uploadURLVariables;
		} */

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