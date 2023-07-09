
# fsync validate

The purpose of this program is to check whether `fsync` actually works:
- Plug the disk you want to test into your PC
- Start the program, set the argument to some file in the disk you want to test
- Program will start writing data to file
- Unplug the drive, or power cable of the drive
- Re-plug the drive, compare content of the test file with the console output

The last `synced line` must always be present in the file.

It's OK if the last `written line` is missing from the drive.

# Run

```bash
go run ./docs/disk-test/fsync-validate/main.go path/to/test/file

# for example:
go run ./docs/disk-test/fsync-validate/main.go g:/test-file
```
