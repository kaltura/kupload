package com.kaltura.upload.business
{
	public class PartnerNotificationVO
	{
		public var url:String;
		public var queryString:String

		public function PartnerNotificationVO(url:String, queryString:String)
		{
			this.url = url;
			this.queryString = queryString;
		}
	}
}