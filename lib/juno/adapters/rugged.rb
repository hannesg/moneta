require 'rugged'
require 'fileutils'

module Juno
  module Adapters

    # A git adapter for juno build upon rugged
    #
    # The methods {#store},{#delete} and {#clear} take the following 
    # options which influence the generated commit message:
    #   :message a commit message (String)
    #   :author an author (a Hash with keys :email, :name and :time )
    #   :commiter same as :author
    #
    # This is not yet thread-safe or multiprocess-safe.
    class Rugged < Base

    protected
      # A shorthand for ::Rugged
      #
      # @api private
      R = ::Rugged
    public

      # Default initializer options
      #
      # @api private
      Defaults = {
        :bare => true,
        :init => true,
        :branch => 'master',
        :'committer.email' => 'juno',
        :'committer.name' => 'juno'
      }.freeze

      # Default initializer.
      #
      # All options apart from :dir are optional.
      #
      # @param [Hash] options
      # @option options [String] :dir the repository directory
      # @option options [String] :branch name of the branch to update (master by default)
      # @option options [TrueClass, FalseClass] :init create the repository if it doens't exist (true by default)
      # @option options [TrueClass, FalseClass] :bare whether to create a bare repository (true by default)
      #
      # @raise [ArgumentError] if no :dir was specified
      # @raise [ArguemntError] if the specified :dir is not a git repository an :init is false
      def initialize(options = {})
        options = Defaults.merge(options)
        raise ArgumentError.new('No option :dir specified') unless @dir = options[:dir]
        FileUtils.mkpath(@dir)
        raise "#{@dir} is not a dir" unless ::File.directory?(@dir)
        @committer = {:email => options[:'committer.email'], :name => options[:'committer.name'] }
        begin
          @repo = R::Repository.new(@dir)
          @bare = @repo.bare?
        rescue R::RepositoryError => e
          if options[:init]
            @repo = R::Repository.init_at(@dir, options[:bare])
          else
            raise ArgumentError.new("The specified option :dir (#{@dir.inspect}) doen't seem to be a git repository. Use :init => true to initialize a git repository automatically.")
          end
        end
        @branch = options[:branch]
      end

      # Test whether a value for the given key exists.
      def key?(key, options = {})
        b = branch
        return false if b.nil?
        return !b.tip.tree[key].nil?
      end

      # Fetches a value for the given key.
      #
      # @param [String] key
      # @param [Hash] options currently not used
      # @return [String, nil]
      def load(key, options = {})
        b = branch
        return nil if b.nil?
        info = b.tip.tree[key]
        return nil if info.nil?
        return @repo.read(info[:oid]).data
      end

      # Stores a value for the given key.
      #
      # @param [String] key
      # @param [String] value
      # @param [Hash] options
      # @return [String] value
      def store(key, value, options = {})
        blob_oid = @repo.write(value, 'blob')
        builder = tree_builder
        builder << {:type => 'blob', :name => key, :oid => blob_oid, :filemode => 33188}
        commit( builder, :message => "store #{key}" )
        return value
      end

      # Deletes the given key and returns the old value if any.
      #
      # This doesn't do anything if the key is not present.
      #
      # @param [String] key
      # @param [Hash] options
      # @return [String, nil]
      def delete(key, options = {})
        b = branch
        return nil if b.nil?
        info = b.tip.tree[key]
        return nil if info.nil?
        builder = tree_builder
        builder.remove(key)
        commit(builder, :message => "delete #{key}")
        return @repo.read(info[:oid]).data
      end

      # Deletes all keys and returns self.
      #
      # @param [Hash] options
      # @return self
      def clear(options = {})
        commit( tree_builder(nil) , :message => "clear")
        return self
      end

    protected

      # Commits a change
      # 
      # This is internally used to create the create the commit 
      # data from a given option hash.
      # 
      # @param [Rugged::TreeBuilder] builder a tree to commit
      # @option options [String] :message a commit message
      # @option options [Hash] :author an author
      #   this must contain the keys :email, :name and :time
      # @option options [Hash] :commiter same as author
      def commit(builder, options)
        b = branch
        tree_oid = builder.write(@repo)
        author = @committer.merge(:time => Time.now)
        options = options.dup
        options[:committer] = author unless options[:committer]
        options[:author] = author unless options[:author]
        options[:tree] = tree_oid
        options[:parents] = Array(options[:parents])
        if b
          options[:parents] << b.tip
        end
        commit = R::Commit.create(
          @repo,
          options
        )
        R::Branch.create(@repo, @branch, commit, true)
      end

      def tree_builder( from = branch )
        case( from )
        when R::Branch
          return tree_builder( from.tip.tree )
        when R::Tree
          builder = R::Tree::Builder.new
          from.each do |x|
            builder << x
          end
          return builder
        when nil
          return R::Tree::Builder.new
        else
          raise ArgumentError, "#{self.class.name}#tree_builder: expected an instance of Rugged::Branch or Rugged::Tree or nil, but got #{from.inspect}"
        end
      end

      def branch
        R::Branch.lookup(@repo, @branch)
      end

    end
  end
end
