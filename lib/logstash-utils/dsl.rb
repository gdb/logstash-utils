require 'logger'

module LogstashUtils
  class DSL
    class CompileError < StandardError; end

    def self.log
      return @log if @log
      @log = Logger.new(STDERR)
      @log.level = Logger::WARN
      @log
    end

    def self.compile_to_file(path, target, options)
      compiled = compile(target, options)
      log.info("Writing the following to #{path}:\n#{compiled}")
      File.open(path, 'w') {|f| f.write(compiled)}
    end

    def self.compile(target, options)
      dsl = self.new(options)
      dsl._compile(target)
    end

    def initialize(options)
      @options = options
    end

    def _compile(target)
      contents = File.read(target)
      @output = []
      @level = 0
      eval(contents, binding, target, 0)
      @output.join.chomp
    end

    # DSL (todo: figure out how to cut out the helper methods

    def args
      @options[:args]
    end

    def assert(condition, message, hard=false)
      return unless condition
      if hard
        raise message
      else
        log.error("Assertion failure: #{message}" + "\n  " + caller.join("\n  "))
      end
    end

    def _directive(method, opts=nil, &blk)
      _emit("#{method} {")
      if opts
        _emit_hash(opts)
      else
        _nested(&blk)
      end
      _emit('}')
      _emit('') if @level == 0
    rescue StandardError => e
      raise CompileError, "#{method} -> #{e}", e.backtrace
    end

    # Unfortunate that this is needed, but it makes the syntax really
    # nice.
    def method_missing(method, *args, &blk)
      if args.length == 0
        raise "Must supply block or a single argument to #{method.inspect} (HINT: make sure you don't have an accidental bareword '#{method.inspect}')" unless blk
      elsif args.length > 1
        raise "At most 1 argument allowed for #{method}"
      end

      _directive(method, args.first, &blk)
    end

    private

    # Override global methods in Rake
    def file(*args, &blk); method_missing(:file, *args, &blk); end

    def _nested(&blk)
      @level += 1
      begin
        blk.call
      ensure
        @level -= 1
      end
    end

    def _emit(string)
      raise "Can only emit strings" unless string.kind_of?(String)
      @output << ' ' * 2 * @level
      @output << string
      @output << "\n"
    end

    def _emit_hash(hash)
      raise "Invalid argument (must be a hash): #{hash.inspect}" unless hash.kind_of?(Hash)
      hash.sort_by {|key, value| key.to_s}.each do |key, value|
        _nested {_emit("#{key} => #{_emitable_value(value)}")} unless value.nil?
      end
    end

    # Don't allow getting too fancy
    def _emitable_value(value)
      case value
      when String
        '"' + value.gsub('"', '\\"') + '"'
      when Array
        '[' + value.map {|member| _emitable_value(member)}.join(', ') + ']'
      when true, false, Numeric
        value
      else
        raise "Not sure how to emit value: #{value.inspect}"
      end
    end
  end
end
