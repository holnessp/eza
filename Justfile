all: build test
all-release: build-release test-release


#----------#
# building #
#----------#

# compile the exa binary
@build:
    cargo build

# compile the exa binary (in release mode)
@build-release:
    cargo build --release --verbose

# produce an HTML chart of compilation timings
@build-time:
    cargo +nightly clean
    cargo +nightly build -Z timings

# check that the exa binary can compile
@check:
    cargo check


#---------------#
# running tests #
#---------------#

# run unit tests
@test:
    cargo test --workspace -- --quiet

# run unit tests (in release mode)
@test-release:
    cargo test --workspace --release --verbose

#-----------------------#
# code quality and misc #
#-----------------------#

# lint the code
@clippy:
    touch src/main.rs
    cargo clippy

# update dependency versions, and checks for outdated ones
@update-deps:
    cargo update
    command -v cargo-outdated >/dev/null || (echo "cargo-outdated not installed" && exit 1)
    cargo outdated

# list unused dependencies
@unused-deps:
    command -v cargo-udeps >/dev/null || (echo "cargo-udeps not installed" && exit 1)
    cargo +nightly udeps

# check that every combination of feature flags is successful
@check-features:
    command -v cargo-hack >/dev/null || (echo "cargo-hack not installed" && exit 1)
    cargo hack check --feature-powerset

# print versions of the necessary build tools
@versions:
    rustc --version
    cargo --version


#---------------#
# documentation #
#---------------#

# build the man pages
@man:
    mkdir -p "${CARGO_TARGET_DIR:-target}/man"
    pandoc --standalone -f markdown -t man man/eza.1.md        > "${CARGO_TARGET_DIR:-target}/man/eza.1"
    pandoc --standalone -f markdown -t man man/eza_colors.5.md > "${CARGO_TARGET_DIR:-target}/man/eza_colors.5"
    pandoc --standalone -f markdown -t man man/eza_colors-explanation.5.md > "${CARGO_TARGET_DIR:-target}/man/eza_colors-explanation.5"

# build and preview the main man page (eza.1)
@man-1-preview: man
    man "${CARGO_TARGET_DIR:-target}/man/eza.1"

# build and preview the colour configuration man page (eza_colors.5)
@man-5-preview: man
    man "${CARGO_TARGET_DIR:-target}/man/eza_colors.5"

# build and preview the colour configuration man page (eza_colors.5)
@man-5-explanations-preview: man
    man "${CARGO_TARGET_DIR:-target}/man/eza_colors-explanation.5"

#---------------#
#    release    #
#---------------#

# If you're not cafkafk and she isn't dead, don't run this!
# 
# usage: release major, release minor, release patch
@release version: 
    cargo bump '{{version}}'
    git cliff -t $(grep '^version' Cargo.toml | head -n 1 | grep -E '([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+)?' -o) > CHANGELOG.md
    cargo check
    nix build -L ./#clippy
    git checkout -b cafk-release-$(grep '^version' Cargo.toml | head -n 1 | grep -E '([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+)?' -o)
    git commit -asm "chore: release $(grep '^version' Cargo.toml | head -n 1 | grep -E '([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+)?' -o)"
    git push
    echo "waiting 10 seconds for github to catch up..."
    sleep 10
    gh pr create --draft --title "chore: release $(grep '^version' Cargo.toml | head -n 1 | grep -E '([0-9]+)\.([0-9]+)\.([0-9]+)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+[0-9A-Za-z-]+)?' -o)" --body "This PR was auto-generated by our lovely just file" --reviewer cafkafk 

# If you're not cafkafk and she isn't dead, you probably don't need to run
# this!
# 
# usage: cross
@cross: 
    rustup toolchain install stable
    mkdir -p ./target/"bin-$(convco version)"

    # Build
    ## Linux
    cross build --target x86_64-unknown-linux-gnu --release
    tar czvf ./target/"bin-$(convco version)"/eza_x86_64-unknown-linux-gnu.tar.gz -C ./target/x86_64-unknown-linux-gnu/release/ ./eza
    cross build --target aarch64-unknown-linux-gnu --release
    tar czvf ./target/"bin-$(convco version)"/eza_aarch64-unknown-linux-gnu.tar.gz -C ./target/aarch64-unknown-linux-gnu/release/ ./eza
    cross build --target arm-unknown-linux-gnueabihf --release
    tar czvf ./target/"bin-$(convco version)"/arm-unknown-linux-gnueabihf.tar.gz -C ./target/arm-unknown-linux-gnueabihf/release/ ./eza
    ## Windows
    cross build --target x86_64-pc-windows-gnu --release
    zip -j ./target/"bin-$(convco version)"/x86_64-pc-windows-gnu.zip ./target/x86_64-pc-windows-gnu/release/eza.exe

    # Generate Checksums
    echo "# Checksums"
    echo "## sha256sum"
    echo "```"
    sha256sum ./target/"bin-$(convco version)"/*
    echo "```"
    echo "## md5sum"
    echo "```"
    md5sum ./target/"bin-$(convco version)"/*
    echo "```"

#---------------------#
# Integration testing #
#---------------------#

# Runs integration tests in nix sandbox
#
# Required nix, likely won't work on windows.
@itest:
    nix build -L ./#trycmd

# Runs integration tests in nix sandbox, and dumps outputs.
#
# WARNING: this can cause loss of work
@idump:
    rm ./tests/cmd/*nix.stderr -f || echo  
    rm ./tests/cmd/*nix.stdout -f || echo
    rm ./tests/ptests/test_tests*.stderr -f || echo  
    rm ./tests/ptests/test_tests*.stdout -f || echo
    nix build -L ./#trydump
    cp ./result/dump/*nix.* ./tests/cmd/
    cp ./result/dump/test_tests*.* ./tests/ptests/

