require 'fileutils'
require 'ostruct'
require 'pathname'

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

   def remove(key)
      path = build_path(key)
      FileUtils.rm(path) if File.exist?(path)
   end

   def clear()
      clear_directory(@base) if File.directory?(@base)
   end

   def clear_directory(dir_path)
      Dir.foreach(dir_path) do |path|
         next if path == '.' || path == '..'

         full_path = File.join(dir_path, path);
         if File.directory?(full_path)
            clear_directory(full_path)
            FileUtils.remove_dir(full_path)
         else
            File.delete(full_path)
         end
      end
   end

   def enumerate_keys(query = nil)
      start_path = @base
      start_path = "#{start_path}/#{query}" if query

      Dir.glob("#{start_path}/**/*").reject { |d| File.directory?(d) }.map(&method(:unbuild_path))
   end

   def empty_to(other)
      FileUtils.cp_r "#{@base}/.", other.base
      clear
   end

   def build_path(key)
      "#{@base}/#{key}.json"
   end

   def unbuild_path(built_path)
      Pathname.new(built_path).relative_path_from(Pathname.new(@base)).to_s[0...-5]
   end
end
