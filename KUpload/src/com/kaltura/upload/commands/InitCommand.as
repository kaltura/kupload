package com.kaltura.upload.commands
{
	import com.kaltura.net.TemplateURLVariables;
	import com.kaltura.upload.enums.KUploadStates;
	import com.kaltura.upload.events.KUploadErrorEvent;
	import com.kaltura.upload.events.KUploadEvent;
	import com.kaltura.upload.vo.FileFilterVO;
	import com.kaltura.utils.KConfigUtil;
	
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
			model.host		= _params.host;
			model.ks 		= _params.ks;
			model.partnerId = _params.partnerId;
			model.subPId 	= _params.subPId;
			model.uid 		= _params.uid;
			model.entryId	= _params.entryId;
			model.partnerData	= _params.partnerData;
			model.uiConfId	= _params.uiConfId;
			if(_params.kuploadUiconfId) model.uiConfId	= _params.kuploadUiconfId;
			model.jsDelegate = _params.jsDelegate;
			
			model.externalInterfaceEnable = _params.externalInterfaceDisabled != '1';
			
			model.permissions 	= _params.permissions;
			model.groupId 		= _params.groupId;
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
					ks: 		model.ks,
					partner_id: model.partnerId,
					subp_id: 	model.subPId,
					uid: 		model.uid
				};
			model.serviceUrl  	= model.host + "/index.php/partnerservices2/upload";
			model.addEntryUrl 	= model.host + "/index.php/partnerservices2/addentry";
			model.uploadUrl = model.uploadHost;
		}
		private function loadConfiguration():void
		{
			var uiConfUrl:String = model.host + "/index.php/partnerservices2/getuiconf"
			//var uiConfUrl = "http://localhost/sf/uiconf.xml"
			
			uiConfUrl += "?partner%5Fid=" + model.partnerId + "&ui%5Fconf%5Fid=" + model.uiConfId + "&uid=" + model.uid + "&subp%5Fid=" + model.subPId + "&ks=" + model.ks;
			trace("uiConfUrl:" + uiConfUrl); 
			
			var urlRequest:URLRequest = new URLRequest(uiConfUrl);
			/* var data:TemplateURLVariables = new TemplateURLVariables(model.baseRequestData);
			data.ui_conf_id = model.uiConfId;

			urlRequest.data = data; */
			_configLoader = new URLLoader(urlRequest);
			_configLoader.addEventListener(Event.COMPLETE, 						configLoaderCompleteHandler);
			_configLoader.addEventListener(IOErrorEvent.IO_ERROR, 				configLoaderIoErrorHandler);
			_configLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,	configLoaderSecurityErrorHandler);
		}

		private function configLoaderCompleteHandler(e:Event):void
		{
			parseConfiguration();
			saveConfigurationFlashVars();
			kuploadReady()
		}
		private function parseConfiguration():void
		{
			var xmlUiConf:XML = XML(_configLoader.data);
			if (xmlUiConf.error.hasComplexContent())
			{
				dispatchUiConfError();
				return;
			}
			var configXml:XML = XML(unescape(xmlUiConf..confFile.text()));
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

			var xmlLimits:XML = configXml.limits[0];
			model.maxUploads 	= KConfigUtil.getDefaultValue(xmlLimits.@maxUploads[0], model.maxUploads);
			model.maxFileSize 	= KConfigUtil.getDefaultValue(xmlLimits.@maxFileSize[0], model.maxFileSize);
			model.maxTotalSize	= KConfigUtil.getDefaultValue(xmlLimits.@maxTotalSize[0], model.maxTotalSize);

			model.conversionProfile	= KConfigUtil.getDefaultValue(configXml.@conversionProfile[0], model.conversionProfile);

			model.serviceUrl = KConfigUtil.getDefaultValue(configXml.@uploadUrl, model.serviceUrl);
			model.serviceUrl = KConfigUtil.getDefaultValue(_params.uploadUrl, model.serviceUrl);

		}

		private function configLoaderIoErrorHandler(e:IOErrorEvent):void
		{
			dispatchUiConfError();
		}

		private function configLoaderSecurityErrorHandler(e:IOErrorEvent):void
		{
			dispatchUiConfError();
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
		}

	}
}