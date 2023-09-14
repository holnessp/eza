#[test]
fn cli_all_tests() {
    trycmd::TestCases::new()
        .case("tests/cmd/*_all.toml");
}

#[test]
#[cfg(unix)]
fn cli_unix_tests() {
    trycmd::TestCases::new()
        .case("tests/cmd/*_unix.toml");
}

#[test]
#[cfg(windows)]
fn cli_windows_tests() {
    trycmd::TestCases::new()
        .case("tests/cmd/*_windows.toml");
}

#[test]
#[cfg(feature="nix")]
fn cli_nix_tests() {
    trycmd::TestCases::new()
        .case("tests/cmd/*_nix.toml");
}

#[test]
#[cfg(feature="powertest")]
fn cli_powertest_tests() {
    trycmd::TestCases::new()
        .case("tests/ptests/*.toml");
}
