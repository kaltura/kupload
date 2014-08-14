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
	import com.swffocus.SWFFocus;
	
	import fl.controls.Button;
	
	import flash.accessibility.AccessibilityProperties;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.system.Security;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.setTimeout;

	public class KUpload extends Sprite {

		public static const VERSION:String = "v1.2.15";

		private var _model:KUploadModelLocator = KUploadModelLocator.getInstance();
		private var _hitArea:MovieClip;


		public function KUpload() {
			Security.allowDomain("*");
			mouseChildren = true;
			SWFFocus.init(this.stage);
			KUploadController.getInstance().registerApp(this);

			addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			init();
		}
		

		/**
		 * notify any listeners something happened 
		 * @param eventName	xxxHandler
		 * @param args	additional arguments
		 * 
		 */		
		public function dispatchActionEvent(eventName:String, args:Array):void {
			var event:ActionEvent = new ActionEvent(eventName, args);
			dispatchEvent(event);
			trace('dispatchEvent: ' + event.type);
		}

		private var _ap:AccessibilityProperties = new AccessibilityProperties();


		private function init():void {
			_ap.name = loaderInfo.parameters.browseBtnName || "Browse File";
			accessibilityProperties = _ap;
			drawFakeBg();

			if (stage)
				addedToStageHandler();
			else
				addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);

		}


		private var _focusInFlag:Boolean;


		private function onFE(focusEvent:FocusEvent):void {
			if (_focusInFlag) {
				trace(focusEvent.type, " ", focusEvent.target);
				_btn.setFocus();
			}
			_focusInFlag = true;
		}

		
		private var _btn:Button = new Button();


		private function addedToStageHandler(addedToStageEvent:Event = null):void {

			_btn.focusEnabled = true;
			var accessProps:AccessibilityProperties = new AccessibilityProperties();
			accessProps.name = "Browse your PC to upload a file";
			_btn.accessibilityProperties = accessProps;
			_btn.width = 0;
			_btn.height = 0;
			_btn.label = "";
			_btn.addEventListener(MouseEvent.CLICK, clickHandler);
			addChild(_btn);

			stage.addEventListener(FocusEvent.FOCUS_IN, onFE);
			removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);

			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			trace("call init command");
			var initCommand:BaseUploadCommand = new InitCommand(loaderInfo.parameters, root.loaderInfo.parameters);
			initCommand.execute();
			_hitArea.addEventListener(MouseEvent.CLICK, clickHandler);

			addCallbacks();

			this.contextMenu = new ContextMenu();
			this.contextMenu.customItems = [new ContextMenuItem("KUpload " + VERSION)];
		}


		/**
		 * create the area where user can click 
		 * @param hitAreaWidth
		 * @param hitAreaHeight
		 * 
		 */
		public function drawFakeBg(hitAreaWidth:Number = 1024, hitAreaHeight:Number = 1024):void {
			if (!_hitArea) {
				_hitArea = new MovieClip();
			}
			_hitArea.graphics.clear();
			_hitArea.graphics.beginFill(0x0000FF, 0);
			_hitArea.graphics.drawRect(0, 0, hitAreaWidth, hitAreaHeight);
			_hitArea.graphics.endFill();
			_hitArea.x = 0;
			_hitArea.y = 0;
			_hitArea.width = hitAreaWidth;
			_hitArea.height = hitAreaHeight;
			_hitArea.accessibilityProperties = _ap;
			_hitArea.name = "hitArea";
			_hitArea.focusRect = true;
			_hitArea.buttonMode = true;
			_hitArea.useHandCursor = true;
			if (loaderInfo.parameters.browseImgSrc) {
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImgLoadComplete, false, 0, true);
				loader.load(new URLRequest(loaderInfo.parameters.browseImgSrc));
			}

			addChild(_hitArea);
		}


		private function onImgLoadComplete(e:Event):void {
			_hitArea.addChild(e.target.content);
		}


		private function clickHandler(clickEvent:MouseEvent = null):void {
			if (_model.state == KUploadStates.READY) {
				browse();
			}
		}

		
		/* *****************************************************
		* API FUNCTIONS
		* *****************************************************/
		
		/**
		 * browse files 
		 */
		public function browse():void {
			var browseCommand:BrowseCommand = new BrowseCommand();
			browseCommand.execute();
		}


		public function addTags(tags:Array, startIndex:int, endIndex:int):void {
			var addTagsCommand:AddTagsCommand = new AddTagsCommand(tags, startIndex, endIndex);
			setTimeout(function():void
			{
				addTagsCommand.execute()
			}, 0);
		}


		public function setTags(tags:Array, startIndex:int, endIndex:int):void {
			var setTagsCommand:SetTagsCommand = new SetTagsCommand(tags, startIndex, endIndex);
			setTimeout(function():void
			{
				setTagsCommand.execute()
			}, 0);
		}


		public function setTitle(title:String, startIndex:int, endIndex:int):void {
			var setTitleCommand:SetTitleCommand = new SetTitleCommand(title, startIndex, endIndex);
			setTimeout(function():void
			{
				setTitleCommand.execute()
			}, 0);
		}


		public function removeFiles(startIndex:int, endIndex:int):void {
			var setTitleCommand:RemoveFilesCommand = new RemoveFilesCommand(startIndex, endIndex);
			setTitleCommand.execute();
		}


		public function upload():void {
			var uploadCommand:UploadCommand = new UploadCommand();
			setTimeout(function():void
			{
				uploadCommand.execute()
			}, 0);
		}


		public function setMediaType(mediaType:String):void {
			var setMediaTypeCommand:SetMediaTypeCommand = new SetMediaTypeCommand(mediaType);
			setTimeout(function():void
			{
				setMediaTypeCommand.execute()
			}, 0);
		}


		public function addEntries():void {
			var addEntries:AddEntriesCommand = new AddEntriesCommand();
			setTimeout(function():void
			{
				addEntries.execute()
			}, 0);
		}


		public function getFiles():Array {
			var files:Array = new Array();
			for each (var file:FileVO in _model.files) {
				files.push(file.file.fileReference.name);
			}
			return files;
		}


		public function getTotalSize():Number {
			return _model.totalSize;
		}


		public function stopUploads():void {
			var stopUploadsCommand:BaseUploadCommand = new StopUploadsCommand();
			stopUploadsCommand.execute()
		}


		public function getError():String {
			return _model.error;
		}


		public function getExceedingFilesIndices():Array {
			return _model.exceedingFilesIndices;
		}


		public function getUploadedErrorIndices():Array {
			return _model.uploadedErrorIndices;
		}


		public function getSelectedErrorIndices():Array {
			return _model.selectedErrorIndices;
		}


		public function setMaxUploads(value:uint):void {
			_model.maxUploads = value;
			var validateLimitations:ValidateLimitationsCommand = new ValidateLimitationsCommand();
			validateLimitations.execute();
		}


		public function setPartnerData(value:String):void {
			_model.context.partnerData = value;
		}


		public function setGroupId(value:String):void {
			_model.context.groupId = value;
		}


		public function setPermissions(value:String):void {

			_model.context.permissions = parseInt(value);
		}


		public function setSiteUrl(value:String):void {
			_model.siteUrl = value;

		}


		public function setScreenName(value:String):void {
			_model.screenName = value;

		}


		private function addCallbacks():void {
			var model:KUploadModelLocator = KUploadModelLocator.getInstance();
			if (model.externalInterfaceEnable) {
				ExternalInterface.addCallback("upload", upload);
				ExternalInterface.addCallback("browse", browse);
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
				ExternalInterface.addCallback("getSelectedErrorIndices", getSelectedErrorIndices);
				ExternalInterface.addCallback("setMaxUploads", setMaxUploads);
				ExternalInterface.addCallback("setPartnerData", setPartnerData);

				ExternalInterface.addCallback("setGroupId", setGroupId);
				ExternalInterface.addCallback("setPermissions", setPermissions);
				ExternalInterface.addCallback("setSiteUrl", setSiteUrl);
				ExternalInterface.addCallback("setScreenName", setScreenName);
			}
		}
		
		/* *****************************************************
		* ACCESSIBILITY RELATED - TAB IN-OUT
		* *****************************************************/
		
		
		/**
		 * indicates shift button is down 
		 */
		private var _isShiftDown:Boolean = false;
		
		
		private function onKeyDown(e:KeyboardEvent):void {
			switch (String(e.keyCode)) {
				case "16": //shift
					_isShiftDown = true;
					break;
			}
		}
		
		
		private function onKeyUp(e:KeyboardEvent):void {
			switch (String(e.keyCode)) {
				case "16": //shift
					_isShiftDown = false;
					break;
				case "9": //tab
					if (_isShiftDown) {
						setTimeout(function():void
						{
							ExternalInterface.call('flashShiftTabOut');
						}, 79);
					}
					break;
				default:
					break;
			}
		}
	}
}
