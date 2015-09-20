require 'fileutils'
require 'ostruct'

class Storage
   def initialize(base)
      @base = base;
   end

   def base() @base; end

   def get(key)
      path = build_path(key)
      return nil unless File.exist?(path)
      OpenStruct.new(JSON.parse(IO.read(path)))
   end

   def put(key, value)
      path = build_path(key)
      dirname = File.dirname(path)
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
      IO.write(path, JSON.pretty_generate(value.to_h))
   end

   def clear()
      FileUtils.rm_r @base if File.directory?(@base)
   end

   def empty_to(other)
      FileUtils.cp_r "#{@base}/.", other.base
      clear
   end

   def build_path(key)
      "#{@base}/#{key}.json"
   end
end
