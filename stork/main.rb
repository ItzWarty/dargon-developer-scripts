require_relative "lib/stork"
command = ARGV[0];
arguments = ARGV.drop(1);

stork = Stork.new();
stork.send(command, arguments);
