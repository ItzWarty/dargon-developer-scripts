require 'io/console'
require 'sem_ver'

$skip_dialogs = false

def prompt_semver(prompt = 'Version?', guess_version = nil)
   g = "";
   g = "(#{guess_version.to_s})" if guess_version;
   return guess_version if $skip_dialogs
   while true
      print "#{prompt} #{g}: "
      input = STDIN.gets.chomp
      input = guess_version.to_s if input.size == 0
      semver = SemVer.parse(input)
      return semver if semver.valid?
   end
end

def prompt(prompt)
   puts "#{prompt}: ";
   return STDIN.gets.comp;
end

def prompt_password(prompt)
   ask("#{prompt}: ") { |q| q.echo = "" }
end

def assert_equals(a, b, message = nil)
   raise "Assertion failed! #{a} != #{b} #{message}" if a != b
end

def bump_patch(semver)
   SemVer.new("#{semver.major}.#{semver.minor}.#{semver.patch+1}")
end

# via http://chrisholtz.com/blog/lets-make-a-ruby-hash-map-method-that-returns-a-hash-instead-of-an-array/
class Hash
   def hmap(&block)
      Hash[self.map {|k, v| block.call(k,v) }]
   end
end

# via https://gist.github.com/botimer/2891186
require 'highline/import'
def yesno(prompt = 'Continue?', default = true)
   s = default ? '[Y/n]' : '[y/N]'
   d = default ? 'y' : 'n'
   a = d if $skip_dialogs
   puts if $skip_dialogs
   until %w[y n].include? a
      a = ask("#{prompt} #{s} ") { |q| q.limit = 1; q.case = :downcase }
      exit(1) if a == "\u0003"
      a = d if a.length == 0
   end
   a == 'y'
end
