# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this project adheres to
[Semantic Versioning](http://semver.org/).

## UNRELEASED

## [0.3.1] - 2017-12-18

### Changed

* Bugfix: Histogram did not get bin sizes as per config
* Bugfix: Gauge incorrectly reported warnings for config following specification

## [0.3.0] - 2017-12-14

### Added

* Perform validation of configuration before booting
* Add support for gauges (to track e.g. total number of started listeners)

### Changed

* Configuration is now driven by config file, instead of internal constants #4

## [0.2.0] - 2017-12-04

### Changed

* Small internal refactorization

## [0.1.0] - 2017-12-04

### Added

* Initial release
