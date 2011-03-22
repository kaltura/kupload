package com.kaltura.upload.commands
{
	import com.kaltura.KalturaClient;
	import com.kaltura.commands.uiConf.UiConfGet;
	import com.kaltura.config.KalturaConfig;
	import com.kaltura.events.KalturaEvent;
	import com.kaltura.net.TemplateURLVariables;
	import com.kaltura.upload.enums.KUploadStates;
	import com.kaltura.upload.events.KUploadErrorEvent;
	import com.kaltura.upload.events.KUploadEvent;
	import com.kaltura.upload.vo.FileFilterVO;
	import com.kaltura.utils.KConfigUtil;
	import com.kaltura.vo.KalturaUiConf;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.FileFilter;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;

	public class InitCommand extends BaseUploadCommand
	{
		private var _params:Object;
		private var _innerParams:Object;
		private var _configLoader:URLLoader;

		public function InitCommand(params:Object, innerParams:Object=null)
		{
			_params = params;
			_innerParams = innerParams;
		}

		override public function execute():void
		{
			trace('execute init command');
			model.state = KUploadStates.INITIALIZING;
			saveBaseFlashVars();

			setModelData();
			loadConfiguration();
		}

		private function saveBaseFlashVars():void
		{
			var config:KalturaConfig = new KalturaConfig();
			var protocol:String;
			var hostFlashvar:String = _params.host;
			//backward competability, support when "http" is inside the "host" flashvar
			if (hostFlashvar.substr(0,4)=="http") {
				//takes the prefix of host, 'http://' or 'https://'
				var protocolEndIndex:int = hostFlashvar.indexOf('//')+2;
				config.protocol = hostFlashvar.substr(0, protocolEndIndex);
				config.domain = hostFlashvar.substr(protocolEndIndex);		
			}
			else {
				config.protocol = _params.protocol;
				config.domain = _params.host;
			}
		
			config.ks = _params.ks;
			config.partnerId = _params.partnerId;

			model.context.kc = new KalturaClient(config);
			model.context.subPartnerId = _params.partnerId;
			model.context.userId = _params.uid;
			model.context.partnerData = _params.partnerData;
			model.context.permissions = _params.permissions;
			model.context.groupId = _params.groupId;
			model.entryId	= _params.entryId;
			model.uiConfId	= _params.uiConfId;
			if(_params.kuploadUiconfId) 
				model.uiConfId	= _params.kuploadUiconfId;
			model.jsDelegate = _params.jsDelegate;
			
			model.externalInterfaceEnable = _params.externalInterfaceDisabled != '1';
			model.siteUrl 		= _params.siteUrl;
			model.screenName 	= _params.screenName;
			
			if(_innerParams != null)
			{
				trace(_innerParams);
				model.uploadHost = _innerParams.uploadHost;
				trace("*** uploadHost:" + model.uploadHost);
			}
		}



		private function setModelData():void
		{
			model.baseRequestData =
				{
					ks: 		model.context.kc.ks,
					partner_id: model.context.kc.partnerId,
					subp_id: 	model.context.subPartnerId,
					uid: 		model.context.userId
				};
		}
		
		/**
		 * request ksu uiconf
		 * */
		private function loadConfiguration():void
		{
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
		private function parseConfiguration(configXml:XML):void
		{
			var xmlFileFilters:XML = configXml.fileFilters[0];
			var fileFilters:Dictionary = new Dictionary();
			var fileFiltersArr:Array = new Array();
			for each (var xmlFileFilter:XML in xmlFileFilters.fileFilter)
			{
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
			model.maxUploads 	= KConfigUtil.getDefaultValue(xmlLimits.@maxUploads[0], model.maxUploads);
			model.maxFileSize 	= KConfigUtil.getDefaultValue(xmlLimits.@maxFileSize[0], model.maxFileSize);
			model.maxTotalSize	= KConfigUtil.getDefaultValue(xmlLimits.@maxTotalSize[0], model.maxTotalSize);

			model.conversionProfile	= KConfigUtil.getDefaultValue(configXml.@conversionProfile[0], model.conversionProfile);
			model.uploadUrl = KConfigUtil.getDefaultValue(configXml.@uploadUrl, model.uploadUrl);

		}

		private function dispatchUiConfError():void
		{
			var notifyShell:NotifyShellCommand = new NotifyShellCommand(KUploadErrorEvent.UI_CONF_ERROR);
			notifyShell.execute();
		}


		private function kuploadReady():void
		{
			model.state = KUploadStates.READY
			var notifyShellCommand:NotifyShellCommand = new NotifyShellCommand(KUploadEvent.READY);
			notifyShellCommand.execute();
		}

		private function saveConfigurationFlashVars():void
		{
			model.quickEdit		= KConfigUtil.getDefaultValue(_params.quickEdit, model.quickEdit);
			model.maxFileSize	= KConfigUtil.getDefaultValue(_params.maxFileSize, 	model.maxFileSize);
			model.maxTotalSize	= KConfigUtil.getDefaultValue(_params.maxTotalSize, 	model.maxTotalSize);
			model.maxUploads	= KConfigUtil.getDefaultValue(_params.maxUploads, 	model.maxUploads);
			model.conversionProfile	= KConfigUtil.getDefaultValue(_params.conversionProfile, model.conversionProfile);
			model.uploadUrl	= KConfigUtil.getDefaultValue(_params.uploadUrl, model.uploadUrl);
		 
		}
		
		private function setFiltersOrder():void
		{
			var fileFilters:Array = new Array();
			var fileFilterVo:FileFilterVO = model.activeFileFilterVO;
			for each(var ffVo:FileFilterVO in model.fileFiltersArr)
			{
				if(ffVo.mediaType == fileFilterVo.mediaType)
				{
					fileFilters.push(ffVo);
					break;
				}
			}
			
			model.selectedFileFilterArr = fileFilters;
		}

	}
}