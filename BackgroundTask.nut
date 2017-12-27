class BackgroundProxy
{
  _worker = null;
}

class BackgroundTask
{
  static function Run();
  static _proxy = BackgroundProxy();
}

function BackgroundTask::Run()
{
  BackgroundTask._proxy._worker._Run();
}
