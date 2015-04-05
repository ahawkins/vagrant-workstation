# Vagrant Workstation

This repo contains a CLI for working with a [Vagrant][] VM containing
multiple projects. For example, say your development environment
contains project A, B, C. They are all similar enough so they can be
existing in the same development VM. Instead of having to keep a SSH
connection and move around the multiple projects, it's possible to do
the work on the host system. This project solves this problem.

This concept was extracts from multiple professional and personal
uses. It was common to have multiple repositories all built and
developed in the same way. We started out with a VM per-project.
This became unmanagable because it required too many resources
(CPU/Memory/Disk Space). Since there was no difference between each
`Vargantfile` (save a few port mappings and the like) it was easier to
combine them into one VM.

## Installation

This repository contains scripts for working with [vagrant][] VM. It
does not contain the `Vagrantfile`. You must provide it (so naturally
you can customize it for your needs).

1. Clone this repository to your computer
1. Ensure `bin/` is on `$PATH`
1. Create a `Vagrantfile` similar to the [example][examples/Vagrantfile].
1. Set the `$WORKSTATION_VARANTFILE` environment variable to path of
	 the file just created.
1. Create directories containing all projects
1. Run `workstation up /path/to/project-directory`

## Usage & Running Commands

The CLI is mostly a proxy for `vagrant ssh` with the appropriate
settings to keep it fast. All native `vagrant` commands are supported
and decorated in some cases. For example `workstation reload` is the
same `vagrant reload`. All options not handled by the CLI are
forwarded to `vagrant`.

The heart of this project `workstation run`. This executes an
arbitrary command in the VM for the correct project. It uses the
current directory or an arbitrary option to select the correct
project. Assume all the projects are in `/work`

	$ mdkir work/project-a work/project-b
	$ cd work/project-a
	$ workstation run make # make for project-a
	$ mdkir work/project-a/foo/bar
	$ workstation run make # works from nested directories
	$ workstation run -p project-b make # Run make for project b
	$ workstation run -p b make # -p uses fuzzy matching

This covers the majority of functionality. Refer to the usage & manual
for more information on configuration & functionality.

## Development

Install [vagrant][] & [bats][]. Then run:

	$ make test

## Contributing

1. Fork it ( https://github.com/ahawkins/vagrant-workstation/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[vagrant]: https://www.vagrantup.com
[bats]: https://github.com/sstephenson/bats
