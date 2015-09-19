require 'fileutils'
require 'ostruct'

class Storage
   def initialize(base)
      @base = base;
   end

   def get(key)
      OpenStruct.new(JSON.parse(IO.read(build_path(key))))
   end

   def put(key, value)
      path = build_path(key)
      dirname = File.dirname(path)
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
      IO.write(path, JSON.pretty_generate(value.to_h))
   end

   def build_path(key)
      "#{@base}/#{key}.json"
   end
end
