class BackgroundProxy
{
  _worker = null;
}

// Implements Singleton pattern.
// Calling Run() will process some short tasks that shouldn't take too long, but should be run frequently.
// The idea is that during long tasks, like pathfinding, we want some quick actions to be done, like cloning
// buses if there is enough money. So during pathfinging, Run() should be called multiple times.
class BackgroundTask
{
  static function Run();
  static _proxy = BackgroundProxy();
}

function BackgroundTask::Run()
{
  BackgroundTask._proxy._worker.Run();
}
