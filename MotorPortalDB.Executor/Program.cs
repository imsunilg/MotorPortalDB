using Microsoft.Extensions.Configuration;
using Npgsql;

var baseDir = AppContext.BaseDirectory;

var config = new ConfigurationBuilder()
    .SetBasePath(baseDir)
    .AddJsonFile("appsettings.json", optional: true)
    .Build();

string host = Environment.GetEnvironmentVariable("PGHOST") ?? config["Database:Host"] ?? "localhost";
int port = int.Parse(Environment.GetEnvironmentVariable("PGPORT") ?? config["Database:Port"] ?? "5432");
string username = Environment.GetEnvironmentVariable("PGUSER") ?? config["Database:Username"] ?? "postgres";
string password = Environment.GetEnvironmentVariable("PGPASSWORD") ?? config["Database:Password"] ?? "postgres";
string adminDatabase = config["Database:AdminDatabase"] ?? "postgres";
string targetDatabase = Environment.GetEnvironmentVariable("PGDATABASE") ?? config["Database:TargetDatabase"] ?? "motorportal";
string schema = config["Database:Schema"] ?? "motorportal";

string scriptsRoot = Path.Combine(baseDir, "scripts");
if (!Directory.Exists(scriptsRoot))
{
    Console.Error.WriteLine($"Scripts folder not found at '{scriptsRoot}'. Build the project so the ../scripts SQL files are copied to the output directory.");
    return 1;
}

string BuildConnectionString(string database) => new NpgsqlConnectionStringBuilder
{
    Host = host,
    Port = port,
    Username = username,
    Password = password,
    Database = database
}.ConnectionString;

try
{
    // Step 1: ensure the target database exists (connect to the admin/maintenance database to do this).
    await using (var adminConn = new NpgsqlConnection(BuildConnectionString(adminDatabase)))
    {
        await adminConn.OpenAsync();

        await using var existsCmd = new NpgsqlCommand("SELECT 1 FROM pg_database WHERE datname = @name", adminConn);
        existsCmd.Parameters.AddWithValue("name", targetDatabase);
        var exists = await existsCmd.ExecuteScalarAsync() is not null;

        if (!exists)
        {
            Console.WriteLine($"Database '{targetDatabase}' does not exist — creating it.");
            await using var createCmd = new NpgsqlCommand($"CREATE DATABASE \"{targetDatabase}\"", adminConn);
            await createCmd.ExecuteNonQueryAsync();
        }
        else
        {
            Console.WriteLine($"Database '{targetDatabase}' already exists.");
        }
    }

    // Step 2: check whether the schema is already populated — if so, this is a no-op.
    await using var targetConn = new NpgsqlConnection(BuildConnectionString(targetDatabase));
    await targetConn.OpenAsync();

    await using var tableCountCmd = new NpgsqlCommand(
        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = @schema", targetConn);
    tableCountCmd.Parameters.AddWithValue("schema", schema);
    var tableCount = (long)(await tableCountCmd.ExecuteScalarAsync())!;

    if (tableCount > 0)
    {
        Console.WriteLine($"Schema \"{schema}\" already has {tableCount} table(s)/view(s) — database structure already initialized, nothing to do.");
        return 0;
    }

    // Step 3: not yet initialized — run every script in the same order as migrate.sh.
    Console.WriteLine("Schema is empty — initializing structure, functions, views and seed data...");

    async Task RunScriptAsync(string path)
    {
        Console.WriteLine($"  -> {Path.GetFileName(path)}");
        var sql = await File.ReadAllTextAsync(path);
        await using var cmd = new NpgsqlCommand(sql, targetConn);
        await cmd.ExecuteNonQueryAsync();
    }

    IEnumerable<string> OrderedSqlFiles(string subfolder) =>
        Directory.GetFiles(Path.Combine(scriptsRoot, subfolder), "*.sql").OrderBy(f => f, StringComparer.Ordinal);

    await RunScriptAsync(Path.Combine(scriptsRoot, "01_create_schema.sql"));

    foreach (var file in OrderedSqlFiles("02_tables"))
        await RunScriptAsync(file);

    await RunScriptAsync(Path.Combine(scriptsRoot, "03_constraints_indexes.sql"));

    foreach (var file in OrderedSqlFiles("04_functions"))
        await RunScriptAsync(file);

    foreach (var file in OrderedSqlFiles("05_views"))
        await RunScriptAsync(file);

    await RunScriptAsync(Path.Combine(scriptsRoot, "06_seed_data.sql"));

    Console.WriteLine("Database initialization complete.");
    return 0;
}
catch (Exception ex)
{
    Console.Error.WriteLine($"Database initialization failed: {ex.Message}");
    return 1;
}
