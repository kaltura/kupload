package {
	import com.kaltura.upload.commands.AddEntriesCommand;
	import com.kaltura.upload.commands.AddTagsCommand;
	import com.kaltura.upload.commands.BaseUploadCommand;
	import com.kaltura.upload.commands.BrowseCommand;
	import com.kaltura.upload.commands.InitCommand;
	import com.kaltura.upload.commands.RemoveFilesCommand;
	import com.kaltura.upload.commands.SetMediaTypeCommand;
	import com.kaltura.upload.commands.SetTagsCommand;
	import com.kaltura.upload.commands.SetTitleCommand;
	import com.kaltura.upload.commands.StopUploadsCommand;
	import com.kaltura.upload.commands.UploadCommand;
	import com.kaltura.upload.commands.ValidateLimitationsCommand;
	import com.kaltura.upload.controller.KUploadController;
	import com.kaltura.upload.enums.KUploadStates;
	import com.kaltura.upload.events.ActionEvent;
	import com.kaltura.upload.model.KUploadModelLocator;
	import com.kaltura.upload.vo.FileVO;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.system.Security;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.setTimeout;

	public class KUpload extends Sprite
	{
		private var _model:KUploadModelLocator = KUploadModelLocator.getInstance();
		private var _hitArea:MovieClip = new MovieClip();
		
		public function KUpload()
		{
			KUploadController.getInstance().registerApp(this);
			init();
		}
		
		public function dispatchActionEvent(eventName:String, args:Array):void
		{
			var event:ActionEvent = new ActionEvent(eventName, args);
			dispatchEvent(event);
			trace('dispatchEvent: ' + event.type);
		}

		private function init():void
		{
			Security.allowDomain("*");
			drawFakeBg();
			if(stage)
				addedToSatgeHandler();
			else
				addEventListener(Event.ADDED_TO_STAGE, addedToSatgeHandler);
		}

		private function addedToSatgeHandler(addedToStageEvent:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, addedToSatgeHandler);
			
			stage.align = StageAlign.TOP_LEFT;
		    stage.scaleMode = StageScaleMode.NO_SCALE;
			trace("call init command");
			var initCommand:BaseUploadCommand = new InitCommand(stage.loaderInfo.parameters, root.loaderInfo.parameters);
			initCommand.execute();
			_hitArea.addEventListener(MouseEvent.CLICK, clickHandler);

			addCallbacks();

			this.contextMenu = new ContextMenu();
			this.contextMenu.customItems = [new ContextMenuItem("KUpload v.1.2")];
		}

		public function drawFakeBg(hitAreaWidth : Number = 1024, hitAreaHeight : Number = 1024):void
		{
			_hitArea.graphics.clear();
		    _hitArea.graphics.beginFill(0xFF0000, 0);
		    _hitArea.graphics.drawRect(0, 0, hitAreaWidth, hitAreaHeight);
		    _hitArea.graphics.endFill();
		    _hitArea.x = 0;
		    _hitArea.y = 0;
		    _hitArea.width = hitAreaWidth;
		    _hitArea.height = hitAreaHeight;
		    _hitArea.buttonMode = true;
		    _hitArea.useHandCursor = true;
		    
		    if(!this.contains(_hitArea))
		   		addChild(_hitArea);

		}
		private function clickHandler(clickEvent:MouseEvent):void
		{
			if (_model.state == KUploadStates.READY)
			{
				browse();
			}
		}

		//API functions
		public function browse():void
		{
			trace("browse()");
			var browseCommand:BrowseCommand = new BrowseCommand();
			browseCommand.execute();
		}

		public function addTags(tags:Array, startIndex:int, endIndex:int):void
		{
			var addTagsCommand:AddTagsCommand = new AddTagsCommand(tags, startIndex, endIndex);
			setTimeout(function():void{ addTagsCommand.execute() }, 0);
		}

		public function setTags(tags:Array, startIndex:int, endIndex:int):void
		{
			var setTagsCommand:SetTagsCommand = new SetTagsCommand(tags, startIndex, endIndex);
			setTimeout(function():void{ setTagsCommand.execute() }, 0);
		}

		public function setTitle(title:String, startIndex:int, endIndex:int):void
		{
			var setTitleCommand:SetTitleCommand = new SetTitleCommand(title, startIndex, endIndex);
			setTimeout(function():void{ setTitleCommand.execute() }, 0);
		}

		public function removeFiles(startIndex:int, endIndex:int):void
		{
			var setTitleCommand:RemoveFilesCommand = new RemoveFilesCommand(startIndex, endIndex);
			setTitleCommand.execute();
		}

		public function upload():void
		{
			var uploadCommand:UploadCommand = new UploadCommand();
			setTimeout(function():void{ uploadCommand.execute() }, 0);
		}

		public function setMediaType(mediaType:String):void
		{
			var setMediaTypeCommand:SetMediaTypeCommand = new SetMediaTypeCommand(mediaType);
			setTimeout(function():void{ setMediaTypeCommand.execute() }, 0);
		}

		public function addEntries():void
		{
			var addEntries:AddEntriesCommand = new AddEntriesCommand();
			setTimeout(function():void{ addEntries.execute() }, 0);
		}

		public function getFiles():Array
		{
			var files:Array = new Array();
			for each (var file:FileVO in _model.files) {
				files.push(file.file.fileReference.name);
			}
			return files;
		}

		public function getTotalSize():uint
		{
			return _model.totalSize;
		}

		public function stopUploads():void
		{
			var stopUploadsCommand:BaseUploadCommand = new StopUploadsCommand();
			stopUploadsCommand.execute()
		}

		public function getError():String
		{
			return _model.error;
		}

		public function getExceedingFilesIndices():Array
		{
			return _model.exceedingFilesIndices;
		}

		public function getUploadedErrorIndices():Array
		{
			return _model.uploadedErrorIndices;
		}

		public function setMaxUploads(value:uint):void
		{
			_model.maxUploads = value;
			var validateLimitations:ValidateLimitationsCommand = new ValidateLimitationsCommand();
			validateLimitations.execute();
		}

		public function setPartnerData(value:String):void
		{
			_model.context.partnerData = value;
		}

		public function setGroupId(value:String):void
		{
			_model.context.groupId = value;
		}

		public function setPermissions(value:String):void
		{

			_model.context.permissions = parseInt(value);
		}

		public function setSiteUrl(value:String):void
		{
			_model.siteUrl = value;

		}

		public function setScreenName(value:String):void
		{
			_model.screenName = value;

		}

		private function addCallbacks():void
		{
			var model:KUploadModelLocator = KUploadModelLocator.getInstance();
			if(model.externalInterfaceEnable)
			{
				ExternalInterface.addCallback("upload", 	upload);
				ExternalInterface.addCallback("addEntries", addEntries);
				ExternalInterface.addCallback("setMediaType", setMediaType);
				ExternalInterface.addCallback("setTags", setTags);
				ExternalInterface.addCallback("addTags", addTags);
				ExternalInterface.addCallback("setTitle", setTitle);
				ExternalInterface.addCallback("getFiles", getFiles);
				ExternalInterface.addCallback("removeFiles", removeFiles);
				ExternalInterface.addCallback("getTotalSize", getTotalSize);
				ExternalInterface.addCallback("stopUploads", stopUploads);
				ExternalInterface.addCallback("getError", getError);
				ExternalInterface.addCallback("getExceedingFilesIndices", getExceedingFilesIndices);
				ExternalInterface.addCallback("getUploadedErrorIndices", getUploadedErrorIndices);
				ExternalInterface.addCallback("setMaxUploads", setMaxUploads);
				ExternalInterface.addCallback("setPartnerData", setPartnerData);
	
				ExternalInterface.addCallback("setGroupId", setGroupId);
				ExternalInterface.addCallback("setPermissions", setPermissions);
				ExternalInterface.addCallback("setSiteUrl", setSiteUrl);
				ExternalInterface.addCallback("setScreenName", setScreenName);
			}
		}
	}
}