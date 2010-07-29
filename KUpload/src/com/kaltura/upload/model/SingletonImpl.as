private static var _instance:KUploadModelLocator;

public function KUploadModelLocator()
{
	if (_instance == null)
	{
		_instance = this;
	}

}

public static function getInstance():KUploadModelLocator
{
	if (_instance == null)
	{
		_instance = new KUploadModelLocator();
	}
	return _instance;
}