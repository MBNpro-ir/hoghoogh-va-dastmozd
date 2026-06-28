using Velopack;

var options = UpdaterOptions.Parse(args);
if (options.Command != "apply" || string.IsNullOrWhiteSpace(options.Source))
{
    Console.Error.WriteLine(
        "Usage: hvm_updater apply --source <url> [--channel <name>] [--wait-pid <pid>] [--silent] [--restart]");
    return 2;
}

try
{
    if (options.WaitPid is int waitPid)
    {
        await WaitForProcessExitAsync(waitPid, TimeSpan.FromSeconds(60));
    }

    var updateOptions = new UpdateOptions
    {
        ExplicitChannel = string.IsNullOrWhiteSpace(options.Channel)
            ? null
            : options.Channel,
    };
    var manager = new UpdateManager(options.Source, updateOptions);
    var update = await manager.CheckForUpdatesAsync();
    if (update is null)
    {
        return 0;
    }

    await manager.DownloadUpdatesAsync(update);
    if (options.WaitPid is int)
    {
        manager.WaitExitThenApplyUpdates(
            update,
            options.Silent,
            options.Restart,
            Array.Empty<string>());
    }
    else if (options.Restart)
    {
        manager.ApplyUpdatesAndRestart(update);
    }
    else
    {
        manager.ApplyUpdatesAndExit(update);
    }

    return 0;
}
catch (Exception ex)
{
    var logPath = Path.Combine(Path.GetTempPath(), $"hvm-velopack-update-{DateTimeOffset.Now:yyyyMMddHHmmss}.log");
    await File.WriteAllTextAsync(logPath, ex.ToString());
    Console.Error.WriteLine($"HvM update failed. Log: {logPath}");
    return 1;
}

static async Task WaitForProcessExitAsync(int pid, TimeSpan timeout)
{
    try
    {
        using var process = System.Diagnostics.Process.GetProcessById(pid);
        await process.WaitForExitAsync().WaitAsync(timeout);
    }
    catch (ArgumentException)
    {
        // The app already exited.
    }
    catch (TimeoutException)
    {
        // Velopack's own updater has a second wait/kill guard; continue.
    }
}

internal sealed class UpdaterOptions
{
    public string? Command { get; private set; }
    public string? Source { get; private set; }
    public string? Channel { get; private set; }
    public int? WaitPid { get; private set; }
    public bool Silent { get; private set; }
    public bool Restart { get; private set; }

    public static UpdaterOptions Parse(string[] args)
    {
        var options = new UpdaterOptions { Command = args.FirstOrDefault() };
        for (var i = 1; i < args.Length; i++)
        {
            switch (args[i])
            {
                case "--source" when i + 1 < args.Length:
                    options.Source = args[++i];
                    break;
                case "--channel" when i + 1 < args.Length:
                    options.Channel = args[++i];
                    break;
                case "--wait-pid" when i + 1 < args.Length:
                    options.WaitPid = int.TryParse(args[++i], out var value)
                        ? value
                        : null;
                    break;
                case "--silent":
                    options.Silent = true;
                    break;
                case "--restart":
                    options.Restart = true;
                    break;
            }
        }

        return options;
    }
}
