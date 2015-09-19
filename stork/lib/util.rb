require 'io/console'
require 'sem_ver'

# via https://gist.github.com/botimer/2891186
require 'highline/import'
def yesno(prompt = 'Continue?', default = true)
  a = ''
  s = default ? '[Y/n]' : '[y/N]'
  d = default ? 'y' : 'n'
  until %w[y n].include? a
    a = ask("#{prompt} #{s} ") { |q| q.limit = 1; q.case = :downcase }
    exit(1) if a == "\u0003"
    a = d if a.length == 0
  end
  a == 'y'
end

def prompt_semver(prompt = 'Version?', guess_version = nil)
   g = "";
   g = "(#{guess_version.to_s})" if guess_version;
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
   return STIN.gets.comp;
end
