#![cfg_attr(all(windows, not(debug_assertions)), windows_subsystem = "windows")]

use std::collections::VecDeque;
use std::env;
use std::error::Error;
use std::fs::{self, File, OpenOptions};
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::{self, Command};
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use zip::ZipArchive;

#[cfg(windows)]
use std::os::windows::process::CommandExt as _;
#[cfg(windows)]
use windows_sys::Win32::Foundation::CloseHandle;
#[cfg(windows)]
use windows_sys::Win32::System::Threading::{OpenProcess, WaitForSingleObject};
#[cfg(windows)]
use windows_sys::Win32::UI::WindowsAndMessaging::MessageBoxW;

type Result<T> = std::result::Result<T, Box<dyn Error>>;

const APP_EXE: &str = "payroll_app.exe";
const WAIT_TIMEOUT_MS: u32 = 120_000;
const WAIT_TIMEOUT_CODE: u32 = 258;
const SYNCHRONIZE_ACCESS: u32 = 0x0010_0000;
const DETACHED_PROCESS: u32 = 0x0000_0008;
const CREATE_NEW_PROCESS_GROUP: u32 = 0x0000_0200;
const MB_OK: u32 = 0x0000_0000;
const MB_ICON_ERROR: u32 = 0x0000_0010;

fn main() {
    let log_path = env::temp_dir().join(format!(
        "hvm-update-{}.log",
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs()
    ));

    if let Err(error) = run(&log_path) {
        log_line(&log_path, &format!("ERROR: {error}"));
        show_error(&format!(
            "HvM update failed. Please check this log:\n{}",
            log_path.display()
        ));
        process::exit(1);
    }
}

fn run(log_path: &Path) -> Result<()> {
    let options = Options::parse(env::args().skip(1).collect())?;
    log_line(log_path, "Updater started.");

    if let Some(pid) = options.wait_pid {
        wait_for_process(pid, WAIT_TIMEOUT_MS)?;
    }
    thread::sleep(Duration::from_millis(700));

    if !options.zip_path.is_file() {
        return Err(invalid_data(format!(
            "Update zip was not found: {}",
            options.zip_path.display()
        ))
        .into());
    }
    if !options.target_dir.is_dir() {
        return Err(invalid_data(format!(
            "Application directory was not found: {}",
            options.target_dir.display()
        ))
        .into());
    }

    let stage_dir = env::temp_dir().join(format!(
        "hvm-update-stage-{}-{}",
        process::id(),
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_millis()
    ));

    fs::create_dir_all(&stage_dir)?;
    let result = apply_update(&options, &stage_dir, log_path);
    let _ = fs::remove_dir_all(&stage_dir);
    result?;

    let _ = fs::remove_file(&options.zip_path);
    log_line(log_path, "Updater finished.");
    Ok(())
}

fn apply_update(options: &Options, stage_dir: &Path, log_path: &Path) -> Result<()> {
    log_line(
        log_path,
        &format!("Extracting {}", options.zip_path.display()),
    );
    extract_zip(&options.zip_path, stage_dir)?;
    let bundle_dir = find_bundle(stage_dir, &options.exe_name)?;

    log_line(
        log_path,
        &format!(
            "Copying files from {} to {}",
            bundle_dir.display(),
            options.target_dir.display()
        ),
    );
    copy_dir_contents(&bundle_dir, &options.target_dir)?;

    let launch_path = options.target_dir.join(&options.exe_name);
    if !launch_path.is_file() {
        return Err(invalid_data(format!(
            "Updated executable was not found: {}",
            launch_path.display()
        ))
        .into());
    }

    if let Some(marker_path) = &options.marker_path {
        if let Some(parent) = marker_path.parent() {
            fs::create_dir_all(parent)?;
        }
        fs::write(marker_path, b"installed")?;
    }

    if options.restart {
        log_line(log_path, &format!("Launching {}", launch_path.display()));
        launch_detached(&launch_path, &options.target_dir)?;
    }
    Ok(())
}

fn extract_zip(zip_path: &Path, destination: &Path) -> Result<()> {
    let file = File::open(zip_path)?;
    let mut archive = ZipArchive::new(file)?;

    for index in 0..archive.len() {
        let mut entry = archive.by_index(index)?;
        let relative = entry
            .enclosed_name()
            .ok_or_else(|| invalid_data("Unsafe path found in update zip"))?;
        let output = destination.join(relative);

        if entry.is_dir() {
            fs::create_dir_all(&output)?;
            continue;
        }
        if let Some(parent) = output.parent() {
            fs::create_dir_all(parent)?;
        }
        let mut output_file = File::create(&output)?;
        io::copy(&mut entry, &mut output_file)?;
    }
    Ok(())
}

fn find_bundle(root: &Path, exe_name: &str) -> Result<PathBuf> {
    let mut queue = VecDeque::from([root.to_path_buf()]);
    while let Some(directory) = queue.pop_front() {
        if directory.join(exe_name).is_file() {
            return Ok(directory);
        }
        for entry in fs::read_dir(&directory)? {
            let entry = entry?;
            if entry.file_type()?.is_dir() {
                queue.push_back(entry.path());
            }
        }
    }
    Err(invalid_data(format!("Update bundle containing {exe_name} was not found")).into())
}

fn copy_dir_contents(source: &Path, destination: &Path) -> Result<()> {
    fs::create_dir_all(destination)?;
    for entry in fs::read_dir(source)? {
        let entry = entry?;
        copy_entry_with_retry(&entry.path(), &destination.join(entry.file_name()))?;
    }
    Ok(())
}

fn copy_entry_with_retry(source: &Path, destination: &Path) -> Result<()> {
    if source.is_dir() {
        fs::create_dir_all(destination)?;
        for entry in fs::read_dir(source)? {
            let entry = entry?;
            copy_entry_with_retry(&entry.path(), &destination.join(entry.file_name()))?;
        }
        return Ok(());
    }

    if let Some(parent) = destination.parent() {
        fs::create_dir_all(parent)?;
    }
    let mut last_error = None;
    for _ in 0..50 {
        match fs::copy(source, destination) {
            Ok(_) => return Ok(()),
            Err(error) => {
                last_error = Some(error);
                thread::sleep(Duration::from_millis(300));
            }
        }
    }
    Err(last_error
        .unwrap_or_else(|| invalid_data("Unable to copy update file"))
        .into())
}

#[cfg(windows)]
fn wait_for_process(pid: u32, timeout_ms: u32) -> Result<()> {
    unsafe {
        let handle = OpenProcess(SYNCHRONIZE_ACCESS, 0, pid);
        if handle.is_null() {
            return Ok(());
        }
        let wait_result = WaitForSingleObject(handle, timeout_ms);
        let _ = CloseHandle(handle);
        if wait_result == WAIT_TIMEOUT_CODE {
            return Err(
                invalid_data(format!("Application process {pid} did not exit in time")).into(),
            );
        }
    }
    Ok(())
}

#[cfg(not(windows))]
fn wait_for_process(_pid: u32, _timeout_ms: u32) -> Result<()> {
    Ok(())
}

fn launch_detached(executable: &Path, working_directory: &Path) -> Result<()> {
    let mut command = Command::new(executable);
    command.current_dir(working_directory);
    #[cfg(windows)]
    command.creation_flags(DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP);
    command.spawn()?;
    Ok(())
}

fn log_line(path: &Path, message: &str) {
    if let Ok(mut file) = OpenOptions::new().create(true).append(true).open(path) {
        let _ = writeln!(file, "{message}");
    }
}

#[cfg(windows)]
fn show_error(message: &str) {
    let message = to_wide(message);
    let title = to_wide("HvM Updater");
    unsafe {
        MessageBoxW(
            std::ptr::null_mut(),
            message.as_ptr(),
            title.as_ptr(),
            MB_OK | MB_ICON_ERROR,
        );
    }
}

#[cfg(not(windows))]
fn show_error(message: &str) {
    eprintln!("{message}");
}

#[cfg(windows)]
fn to_wide(value: &str) -> Vec<u16> {
    value.encode_utf16().chain(std::iter::once(0)).collect()
}

fn invalid_data(message: impl Into<String>) -> io::Error {
    io::Error::new(io::ErrorKind::InvalidData, message.into())
}

#[derive(Debug)]
struct Options {
    zip_path: PathBuf,
    target_dir: PathBuf,
    exe_name: String,
    wait_pid: Option<u32>,
    marker_path: Option<PathBuf>,
    restart: bool,
}

impl Options {
    fn parse(args: Vec<String>) -> Result<Self> {
        if args.first().map(String::as_str) != Some("apply") {
            return Err(invalid_data(
                "Usage: hvm_updater apply --zip <path> --target <dir> --exe <name> [--wait-pid <pid>] [--marker <path>] [--restart]",
            )
            .into());
        }

        let mut zip_path = None;
        let mut target_dir = None;
        let mut exe_name = APP_EXE.to_string();
        let mut wait_pid = None;
        let mut marker_path = None;
        let mut restart = false;
        let mut index = 1;

        while index < args.len() {
            match args[index].as_str() {
                "--zip" => zip_path = Some(PathBuf::from(next_value(&args, &mut index)?)),
                "--target" => target_dir = Some(PathBuf::from(next_value(&args, &mut index)?)),
                "--exe" => exe_name = next_value(&args, &mut index)?,
                "--wait-pid" => wait_pid = Some(next_value(&args, &mut index)?.parse::<u32>()?),
                "--marker" => marker_path = Some(PathBuf::from(next_value(&args, &mut index)?)),
                "--restart" => restart = true,
                flag => return Err(invalid_data(format!("Unknown option: {flag}")).into()),
            }
            index += 1;
        }

        if Path::new(&exe_name).components().count() != 1 {
            return Err(invalid_data("Executable must be a file name").into());
        }

        Ok(Self {
            zip_path: zip_path.ok_or_else(|| invalid_data("--zip is required"))?,
            target_dir: target_dir.ok_or_else(|| invalid_data("--target is required"))?,
            exe_name,
            wait_pid,
            marker_path,
            restart,
        })
    }
}

fn next_value(args: &[String], index: &mut usize) -> Result<String> {
    *index += 1;
    args.get(*index)
        .cloned()
        .ok_or_else(|| invalid_data("Missing option value").into())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_apply_options() {
        let options = Options::parse(vec![
            "apply".into(),
            "--zip".into(),
            "update.zip".into(),
            "--target".into(),
            "app".into(),
            "--wait-pid".into(),
            "42".into(),
            "--marker".into(),
            "done.marker".into(),
            "--restart".into(),
        ])
        .unwrap();

        assert_eq!(options.zip_path, PathBuf::from("update.zip"));
        assert_eq!(options.target_dir, PathBuf::from("app"));
        assert_eq!(options.exe_name, APP_EXE);
        assert_eq!(options.wait_pid, Some(42));
        assert!(options.restart);
    }

    #[test]
    fn rejects_executable_paths() {
        let result = Options::parse(vec![
            "apply".into(),
            "--zip".into(),
            "update.zip".into(),
            "--target".into(),
            "app".into(),
            "--exe".into(),
            "nested/payroll_app.exe".into(),
        ]);

        assert!(result.is_err());
    }
}
