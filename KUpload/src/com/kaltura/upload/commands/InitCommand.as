package com.kaltura.upload.commands {
	import com.kaltura.KalturaClient;
	import com.kaltura.commands.uiConf.UiConfGet;
	import com.kaltura.config.KalturaConfig;
	import com.kaltura.events.KalturaEvent;
	import com.kaltura.net.TemplateURLVariables;
	import com.kaltura.upload.enums.KUploadStates;
	import com.kaltura.upload.errors.KsuError;
	import com.kaltura.upload.events.KUploadErrorEvent;
	import com.kaltura.upload.events.KUploadEvent;
	import com.kaltura.upload.vo.FileFilterVO;
	import com.kaltura.utils.KConfigUtil;
	import com.kaltura.vo.KalturaUiConf;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.FileFilter;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;
	import flash.utils.Timer;

	public class InitCommand extends BaseUploadCommand {
		static private const MAP_PAIR_DLM:String = ";";
		static private const MAP_KEYS_VAL_DLM:String = ":";
		static private const MAP_KEY_LIST_DLM:String = ",";

		private var _params:Object;
		private var _innerParams:Object;
		private var _configLoader:URLLoader;


		public function InitCommand(params:Object, innerParams:Object = null) {
			_params = params;
			_innerParams = innerParams;
		}


		override public function execute():void {
			trace('execute init command');
			model.state = KUploadStates.INITIALIZING;
			saveBaseFlashVars();

			setModelData();
			loadConfiguration();
		}


		private function saveBaseFlashVars():void {
			var config:KalturaConfig = new KalturaConfig();
			var hostFlashvar:String = _params.host;

			if (_params.hasOwnProperty("protocol")) {
				//backward compatibility, support when "http" is inside the "host" flashvar
				if (hostFlashvar.substr(0, 4) == "http") {
					//takes the prefix of host, 'http://' or 'https://'
					var protocolEndIndex:int = hostFlashvar.indexOf('//') + 2;
					config.protocol = hostFlashvar.substr(0, protocolEndIndex);
					config.domain = hostFlashvar.substr(protocolEndIndex);
				}
				else {
					config.protocol = _params.protocol;
					config.domain = _params.host;
				}

			}
			else {
				//support local testing
				config.protocol = "http://";
				config.domain = "www.kaltura.com";
			}


			config.ks = _params.ks;
			config.partnerId = _params.partnerId;

			model.context.kc = new KalturaClient(config);
			model.context.subPartnerId = _params.partnerId;
			model.context.userId = _params.uid;
			model.context.partnerData = _params.partnerData;
			model.context.permissions = _params.permissions;
			model.context.groupId = _params.groupId;
			model.entryId = _params.entryId;
			model.uiConfId = _params.uiConfId;
			if (_params.kuploadUiconfId)
				model.uiConfId = _params.kuploadUiconfId;
			model.jsDelegate = _params.jsDelegate;

			model.externalInterfaceEnable = _params.externalInterfaceDisabled != '1';
			model.siteUrl = _params.siteUrl;
			model.screenName = _params.screenName;

			if (_innerParams != null) {
				model.uploadHost = _innerParams.uploadHost;
			}
		}



		private function setModelData():void {
			model.baseRequestData = {ks: model.context.kc.ks,
					partner_id: model.context.kc.partnerId,
					subp_id: model.context.subPartnerId,
					uid: model.context.userId};
		}


		/**
		 * request ksu uiconf
		 * */
		private function loadConfiguration():void {
			var uiconfGet:UiConfGet = new UiConfGet(parseInt(model.uiConfId));
			uiconfGet.addEventListener(KalturaEvent.COMPLETE, uiconfResult);
			uiconfGet.addEventListener(KalturaEvent.FAILED, uiconfFault);
			model.context.kc.post(uiconfGet);
		}


		private function uiconfFault(info:Object):void {
			var notifyShell:NotifyShellCommand = new NotifyShellCommand(KUploadErrorEvent.UI_CONF_ERROR);
			notifyShell.execute();
		}


		private function uiconfResult(event:KalturaEvent):void {
			var result:KalturaUiConf = event.data as KalturaUiConf;
			parseConfiguration(new XML(result.confFile));
			saveConfigurationFlashVars();
			kuploadReady();

		}


		/**
		 * parse uiconf xml
		 * */
		private function parseConfiguration(configXml:XML):void {
			var xmlFileFilters:XML = configXml.fileFilters[0];
			var fileFilters:Dictionary = new Dictionary();
			var fileFiltersArr:Array = new Array();
			for each (var xmlFileFilter:XML in xmlFileFilters.fileFilter) {
				var description:String = xmlFileFilter.@description;
				var extensions:String = xmlFileFilter.@extensions;

				var singlefileFilter:FileFilter = new FileFilter(description, extensions);
				var entryType:String = xmlFileFilter.@entryType;
				var mediaType:String = xmlFileFilter.@mediaType;
				var fileFilterVo:FileFilterVO = new FileFilterVO(singlefileFilter, mediaType, entryType);

				fileFilters[xmlFileFilter.@id.toString()] = fileFilterVo;

				fileFiltersArr.push(fileFilterVo);
			}
			model.fileFilterVoList = fileFilters;
			model.fileFiltersArr = fileFiltersArr;
			model.activeFileFilterVO = fileFilters[xmlFileFilters.@default.toString()];
			if (model.activeFileFilterVO)
				setFiltersOrder();

			var xmlLimits:XML = configXml.limits[0];
			model.maxUploads = KConfigUtil.getDefaultValue(xmlLimits.@maxUploads[0], model.maxUploads);
			model.maxFileSize = KConfigUtil.getDefaultValue(xmlLimits.@maxFileSize[0], model.maxFileSize);
			model.maxTotalSize = KConfigUtil.getDefaultValue(xmlLimits.@maxTotalSize[0], model.maxTotalSize);

			model.conversionProfile = KConfigUtil.getDefaultValue(configXml.@conversionProfile[0], model.conversionProfile);
			model.uploadUrl = KConfigUtil.getDefaultValue(configXml.@uploadUrl, model.uploadUrl);

			var map:Object = parseCMUIVar(configXml);
			model.conversionMapping = map != null ? map : model.conversionMapping;
		}


		// Parses the conversion mapping from the loaded UIconf
		private function parseCMUIVar(configXml:XML):Object {
			var map:Object = new Object();
			if (configXml.conversionMapping.length() > 0 && configXml.conversionMapping.profile.length() > 0) {
				var profileList:XMLList = configXml.conversionMapping[0].profile;
				for each (var profile:XML in profileList) {
					var convID:String = profile.@id.toString();
					var extStrs:Array = profile.@extensions.toString().split(";");
					for each (var extStr:String in extStrs) {

						// Converting letter capitalization to lower case to enable ignore case later.
						var extension:String = (extStr.split(".")[1] as String).toLowerCase();
						map[extension] = convID;
					}
				}
			}
			else {
				return null;
			}

			return map;
		}


		private function dispatchUiConfError():void {
			var notifyShell:NotifyShellCommand = new NotifyShellCommand(KUploadErrorEvent.UI_CONF_ERROR);
			notifyShell.execute();
		}


		private function kuploadReady():void {
			model.state = KUploadStates.READY
			var notifyShellCommand:NotifyShellCommand = new NotifyShellCommand(KUploadEvent.READY);
			notifyShellCommand.execute();
		}


		private function saveConfigurationFlashVars():void {
			model.quickEdit = KConfigUtil.getDefaultValue(_params.quickEdit, model.quickEdit);
			model.maxFileSize = KConfigUtil.getDefaultValue(_params.maxFileSize, model.maxFileSize);
			model.maxTotalSize = KConfigUtil.getDefaultValue(_params.maxTotalSize, model.maxTotalSize);
			model.maxUploads = KConfigUtil.getDefaultValue(_params.maxUploads, model.maxUploads);
			model.conversionProfile = KConfigUtil.getDefaultValue(_params.conversionProfile, model.conversionProfile);
			model.uploadUrl = KConfigUtil.getDefaultValue(_params.uploadUrl, model.uploadUrl);

			if (_params.conversionMapping != null) {
				var map:Object = parseCMFlashVar(_params.conversionMapping);
				model.conversionMapping = map != null ? map : model.conversionMapping;
			}
		}


		// Parses the conversion mapping from a properly formatted string 
		private function parseCMFlashVar(value:String):Object {
			var mapObj:Object = new Object();
			var pairs:Array = value.split(MAP_PAIR_DLM);
			for each (var pair:String in pairs) {
				if (pair.length > 0) {
					if (pair.indexOf(MAP_KEYS_VAL_DLM) != -1) {
						var keysNValue:Array = pair.split(MAP_KEYS_VAL_DLM);
						var keysStr:String = keysNValue[0] as String;
						var keys:Array = keysStr.split(MAP_KEY_LIST_DLM);
						var convProfile:String = keysNValue[1] as String;
						for each (var extension:String in keys) {

							// Converting letter capitalization to lower case to enable ignore case later.
							var lowerExt:String = extension.toLowerCase();
							if (mapObj[lowerExt] == null) {
								mapObj[lowerExt] = convProfile;
							}
						}
					}
					else {
						prepareWarningError("The conversionMapping flashVar is formatted incorrectly. The keys and conversion profile ID in each set must be seperated by a colon (:) sign.");
						return null;
					}
				}
			}

			return mapObj;
		}


		private function prepareWarningError(message:String):void {
			function warningErrorTimerHandler(evt:TimerEvent):void {
				var timer:Timer = evt.target as Timer
				throw new KsuError("Warning: " + message, KsuError.WARNING);
			}
			var timer:Timer = new Timer(0, 1);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, warningErrorTimerHandler);
			timer.start();
		}


		private function setFiltersOrder():void {
			var fileFilters:Array = new Array();
			var fileFilterVo:FileFilterVO = model.activeFileFilterVO;
			for each (var ffVo:FileFilterVO in model.fileFiltersArr) {
				if (ffVo.mediaType == fileFilterVo.mediaType) {
					fileFilters.push(ffVo);
					break;
				}
			}

			model.selectedFileFilterArr = fileFilters;
		}

	}
}
