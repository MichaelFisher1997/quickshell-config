set shell := ["bash", "-euo", "pipefail", "-c"]

default:
    @just --list

run:
    quickshell --path ./config

lint:
    qmllint -I "$QUICKSHELL_QML_PATH" -I "$QT_QML_PATH" $(find config -name '*.qml')

fmt:
    qmlformat --inplace $(find config -name '*.qml')

check:
    nix flake check --no-build
    just lint

update:
    nix flake update
