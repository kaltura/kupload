<html>
<head>

<!--include external scripts and define constants -->
<?php 
	require_once("kaltura_client_v3/KalturaClient.php"); 
	
	//define constants
	define("KALTURA_PARTNER_ID", 321011);
	define("KALTURA_PARTNER_WEB_SERVICE_SECRET", "5832f358f01e0b0da9c2cb64ff7f05b2");
	
	define("KSU_UICONFID", 25740421); 
	
	//define session variables
	$partnerUserID          = 'yuval';
	
	
	//Construction of Kaltura objects for session initiation
	$config           = new KalturaConfiguration(KALTURA_PARTNER_ID);
	$client           = new KalturaClient($config);
	$ks               = $client->session->start(KALTURA_PARTNER_WEB_SERVICE_SECRET, $partnerUserID, KalturaSessionType::USER, KALTURA_PARTNER_ID);

?>

<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/swfobject/2.2/swfobject.js"></script>

<!---set style to enable widget overlap -->
<style>
	body { margin: 0px; overflow:hidden }
	#flashContainer{ position:relative; }
		#flashContainer span{ color:#333; font-size:16px; }
		object, embed{ position:relative; top:-40; left:0; z-index:999;}
</style>

<!---	JavaScript handler methods to react to upload events. -->
<script type="text/javascript">
	var flashObj;
	var delegate = {};
	
	var txtResults = "";
	var UploadProgressText = "";
	var UploadProgressTitle = "";

	//KSU handlers

	//This handler checks if the SWF object was loaded or not
	delegate.readyHandler = function()
	{
		flashObj = document.getElementById("uploader");
		var pLoad = confirm("Uploader object loaded successfully!\n\nClick 'OK' to continue to the next step.");
		
		if(pLoad)
		{
			parent.parent.frames["Steps"].document.getElementById("Step0").style.display = "none";
			parent.parent.frames["Steps"].document.getElementById("Step1").style.display = "";
		}
	}

	//This handler knows when content was selected for upload
	delegate.selectHandler = function()
	{
		parent.parent.frames["Steps"].document.getElementById("Step1").style.display = "none";
		parent.parent.frames["Steps"].document.getElementById("Step2").style.display = "";
		parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "Total size to upload: " + flashObj.getTotalSize() + "\n\n";
		txtResults = parent.frames["Results"].document.getElementById("txtResults").value;
		parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "Error: " + flashObj.getError() + "\n\n";
		parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "Error Indices: " + flashObj.getSelectedErrorIndices() + "\n\n";
	}

	//This handler fires when a single file is done uploading
	delegate.singleUploadCompleteHandler = function(args)
	{
		parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "Single file done uploading: " + args[0].title + "\n";
		//alert(args[0]); //.status);
	}

	//This handler fires when all files are done uploading
	delegate.allUploadsCompleteHandler = function()
	{
		parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "All files done uploading.\n\n";
		parent.parent.frames["Steps"].document.getElementById("Step2.1").style.display = "none";
		parent.parent.frames["Steps"].document.getElementById("Step3").style.display = "";
		//flashObj = document.getElementById("uploader");
		//alert(flashObj.getError());
		
	}

	//This handler fires up when the uploaded files are set as entries in the KMC.
	delegate.entriesAddedHandler = function(entries)
	{
		parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "Done!\n\n";
		var txtEntries = "";
		for(var i=0;i<entries.length;i++)
		{
			txtEntries = txtEntries + "* " + entries[i].title + ": " + entries[i].entryId + "\n";
		}
		parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + txtEntries + "\n\n";
		parent.parent.frames["Steps"].document.getElementById("Step3").style.display = "none";
		parent.parent.frames["Steps"].document.getElementById("Step4").style.display = "";
	}

	//This handler returns the upload progress for each file selected for uploading
	delegate.progressHandler = function(args)
	{
		UploadProgressText = "Uploading - " + args[2].title + ": " + args[0] + " / " + args[1];
		parent.frames["Results"].document.getElementById("txtResults").value = txtResults + UploadProgressText + "\n\n";
	}

	delegate.uiConfErrorHandler = function()
	{
		console.log("ui conf loading error");
	}

	<!--- JavaScript callback methods to activate Kaltura services via the KSU widget.-->
	
	//This function fires the upload
	function upload()
	{
		flashObj.upload();
		parent.parent.frames["Steps"].document.getElementById("Step2").style.display = "none";
		parent.parent.frames["Steps"].document.getElementById("Step2.1").style.display = "";
	}

	function setTags(tags, startIndex, endIndex)
	{
		flashObj.setTags(tags, startIndex, endIndex);
	}

	function addTags(tags, startIndex, endIndex)
	{
		flashObj.addTags(tags, startIndex, endIndex);
	}
	
	function setTitle(title, startIndex, endIndex)
	{
		flashObj.setTitle(title, startIndex, endIndex);
	}

	function getFiles()
	{
		var files = flashObj.getFiles();
		parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "Here are the uploaded files:\n-----------------------------\n";
		for(var i=0;i<files.length;i++)
		{
			parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "* " + files[i] + "\n\n";
		}
		parent.parent.frames["Steps"].document.getElementById("Step4").style.display = "none";
		parent.parent.frames["Steps"].document.getElementById("Step5").style.display = "";
	}

	//This function connect to the Kaltura networks and adds the uploaded content as entries into the KMC
	function addEntries()
	{
		flashObj.addEntries();
		parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "Setting entries. Please wait ... "
	}

	//This function stops all active uploads
	function stopUploads()
	{
		flashObj.stopUploads();
		parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "All active uploads stopped.\n\n";
	}

	function setMaxUploads(value)
	{
		flashObj.setMaxUploads(value);
	}
	
		function setPartnerData(value)
	{
		flashObj.setPartnerData(value);
	}

	function setMediaType()
	{
		var mediaType = mediaTypeInput.value;
		console.log(mediaType);
		flashObj.setMediaType(mediaType);
	}

	function addTagsFromForm()
	{
		var tags = document.getElementById("tagsInput").value.split(",");
		var startIndex = parseInt(tagsStartIndex.value);
		var endIndex = parseInt(tagsEndIndex.value);

		parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "The following tags will be added to the desired content: \n"
		for(var i=0;i<tags.length;i++)
		{
			parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "* " + tags[i] + "\n";
		}
		parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "\n";
		addTags(tags, startIndex, endIndex);
	}

	function setTagsFromForm()
	{
		var tags = document.getElementById("tagsInput").value.split(",");
		var startIndex = parseInt(tagsStartIndex.value);
		var endIndex = parseInt(tagsEndIndex.value);

		parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "The following tags will be set to the desired content: \n"
		for(var i=0;i<tags.length;i++)
		{
			parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "* " + tags[i] + "\n";
		}
		parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "\n";
		setTags(tags, startIndex, endIndex);
	}

	function setTitleFromForm()
	{
		var startIndex = parseInt(titleStartIndex.value);
		var endIndex = parseInt(titleEndIndex.value);

		parent.frames["Results"].document.getElementById("txtResults").value = parent.frames["Results"].document.getElementById("txtResults").value + "The following title will be set to the desired content: " + titleInput.value + "\n\n"
		setTitle(titleInput.value, startIndex, endIndex);
	}

	function removeFilesFromForm()
	{
		var startIndex = parseInt(removeStartIndex.value);
		var endIndex = parseInt(removeEndIndex.value);
		flashObj.removeFiles(startIndex, endIndex)
		console.log(flashObj.getTotalSize());
	}

	function setGroupId(value)
	{
		flashObj.setGroupId(value);
	}

	function setPermissions(value)
	{
		flashObj.setPermissions(value);
	}

	function setSiteUrl(value)
	{
		flashObj.setSiteUrl(value);
	}

	function setScreenName(value)
	{
		flashObj.setScreenName(value);
	}

	//set parameters to be taken from user input field
	var tagsInput;
	var tagsStartIndex;
	var tagsEndIndex;

	var titleInput;
	var titleStartIndex;
	var titleEndIndex;

	var removeStartIndex;
	var removeEndIndex;
	var maxUploadsInput;

	var partnerDataInput;
	var mediaTypeInput
	var groupId;
	var permissions;
	var screenName;
	var siteUrl;

	function onLoadHandler()
	{
		tagsInput = document.getElementById("tagsInput");
		tagsStartIndex = document.getElementById("tagsStartIndex");
		tagsEndIndex = document.getElementById("tagsEndIndex");

		titleInput = document.getElementById("titleInput");
		titleStartIndex = document.getElementById("titleStartIndex");
		titleEndIndex = document.getElementById("titleEndIndex");

		removeStartIndex = document.getElementById("removeStartIndex");;
		removeEndIndex = document.getElementById("removeEndIndex");

		maxUploadsInput = document.getElementById("maxUploadsInput");
		partnerDataInput = document.getElementById("partnerDataInput");

		groupId = document.getElementById("groupId");
		permissions = document.getElementById("permissions");
		screenName = document.getElementById("screenName");
		siteUrl = document.getElementById("siteUrl");
		mediaTypeInput = document.getElementById("mediaTypeInput");
	}
</script>


</head>
<body onload=onLoadHandler()>
	<SPAN id="flashContainer">
		<form>
			<BR />
			<input type="button" value="Step 1 - Browse for content">
		</form>
		<SPAN id="uploader"></SPAN>
		
		<script language="JavaScript" type="text/javascript">
                var params = {
                            allowScriptAccess: "always",
                            allowNetworking: "all",
                            wmode: "transparent"
                };
                var attributes = {
                            id: "uploader",
                            name: "KUploader"
                };
                // set flashVar object
                var flashVars = {
							uid: "<?PHP echo "$partnerUserID" ?>",
							partnerId: <?php echo KALTURA_PARTNER_ID; ?>,
							entryId: -1,
							ks: "<?PHP echo "$ks" ?>",
							uiConfId: <?php echo KSU_UICONFID; ?>,
							jsDelegate: "delegate" };
				
                swfobject.embedSWF("http://www.kaltura.com/kupload/ui_conf_id/<?php echo KSU_UICONFID; ?>", "uploader", "180", "20", "9.0.0", "expressInstall.swf",flashVars, params,attributes);
		</script>
	

	
	</SPAN>
	<SPAN id="userInput">
		<form>
			<input type="text" id="mediaTypeInput" />
			<input type="button" value="Set media type" onclick="setMediaType()">
		</form>

		<form>
			<input type="text" value="enter tags here" id="tagsInput" />
			<input type="text" value="0" id="tagsStartIndex" />
			<input type="text" value="1" id="tagsEndIndex" />
			<input type="button" value="Add tags" onclick="addTagsFromForm()">
			<input type="button" value="Set tags" onclick="setTagsFromForm()">
		</form>

		<form>
			<input type="text" value="enter title here" id="titleInput" />
			<input type="text" value="0" id="titleStartIndex" />
			<input type="text" value="1" id="titleEndIndex" />
			<input type="button" value="Set title" onclick="setTitleFromForm()">
		</form>

		<form>
			<input type="text" value="0" id="removeStartIndex" />
			<input type="text" value="0" id="removeEndIndex" />
			<input type="button" value="Remove Files" onclick="removeFilesFromForm()">
		</form>

		<form>
			<input type="text" value="0" id="maxUploadsInput" />
			<input type="button" value="Set max uploads" onclick="setMaxUploads(parseInt(maxUploadsInput.value))">
		</form>

		<form>
			<input type="text" value="partner data goes here" id="partnerDataInput" />
			<input type="button" value="Set partner data" onclick="setPartnerData(partnerDataInput.value)">
			<input id="groupId" />
			<input type="button" value="set group id " onClick="setGroupId(groupId.value)">
			<input id="permissions" />
			<input type="button" value="set permissions" onClick="setPermissions(permissions.value)">
			<input id="screenName" />
			<input type="button" value="Set screen name" onClick="setScreenName(screenName.value)">
			<input id="siteUrl" />
			<input type="button" value="set site url" onClick="setSiteUrl(siteUrl.value)">
		</form>

		<form>
			<input type="button" value="Step 2 - Upload selected content" onclick="upload()">
			&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
			<input type="button" value="Step 3 - Add entries" onclick="addEntries()">
			&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
			<input type="button" value="Cancel uploads" onclick="stopUploads()">
		</form>

		<form>
			<input type="button" value="Step 4 - Get Files" onclick="getFiles()">
		</form>
		<form>
		</form>
	</SPAN>
</body>
</html>