
# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.1.1] - 2017-03-23
### Fixed error in !install-plugin command when installing plugins that had a dependency on the PoshBot module.

## [0.1.0] - 2017-03-21
### Added
- Initial documentation for mkdocs
- New function to create scheduled task to run PoshBot
- New builtin command to get recent command execution history
- Commands to remove plugins/roles/groups
- Support for multiple plugin versions

### Changed
- Standadized builtin bot command parameter names
- Move demo commands (WolframAlpha, Giphy) into seperate plugin repos
- Move network plugin into seperate repo

### Fixed
- Fix StopUpstreamCommandsException exception from being thrown in Install-Plugin command

## [0.0.1] - 2016-12-18
### Added
- Initial commit
